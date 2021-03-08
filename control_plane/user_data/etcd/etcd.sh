#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

cluster="${cluster}"
role="${role}"
etcd_data_dir="/var/lib/etcd"

####################################################################################################
# Gather details about whether there's currently a cluster to which this instance belongs
####################################################################################################
log "Looking for other etcd cluster members with similar instance tags..."
region=$( curl -sSLf "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq ".region" -rec )
potential_cluster_members=$(
    aws ec2 describe-instances \
        --region="$region" \
        --output="json" \
        --filters \
            "Name=tag:Cluster,Values=$cluster" \
            "Name=tag:Role,Values=$role" \
            "Name=instance-state-name,Values=running" \
    | jq ".Reservations[].Instances[].PrivateIpAddress" -rec
)

# In the event multiple instances are starting up a new cluster at once, whichever has the lexigraphically earlier IP wins.
cold_starter=$( echo "$potential_cluster_members" | sort | head -n1 )
cluster_to_join=""
is_former_member="false"

if [[ "$potential_cluster_members" != "" ]]; then
    log "Instances were found with similar tags.  Checking to see if there's a running etcd cluster on any..."
    for potential_cluster_member in $potential_cluster_members; do
        curl -sSL "http://$potential_cluster_member:2379/health" > "/dev/null" 2>&1 && {
            cluster_to_join="$potential_cluster_member"
            break
        } || true
    done
fi

if [[ "$cluster_to_join" != "" ]]; then
    log "A cluster was found, checking if this instance is already registered with it..."
    if etcdctl --endpoints="http://$cluster_to_join:2379" member list -w simple | grep " $(hostname)," > "/dev/null"; then
        is_former_member="true"
    fi
fi

####################################################################################################
# Start etcd
####################################################################################################

# General model:
# - A cluster exists, and I'm not a member
# - A cluster exists, and I'm a member
# - No cluster exists, but I can start one
# - No cluster exists, and I can't start one
#
# All four scenarios

if [[ "$cluster_to_join" != "" && "$is_former_member" == "false" ]]; then
    log "Found a running etcd server on an instance with similar tags to which this instance is not registered.  Attempting to join it..."

    if [[ -d "$etcd_data_dir/member" ]]; then
        log "Clearing out old data directory [$etcd_data_dir]..."
        rm -rf "$etcd_data_dir/member"
    fi

    cluster_config=$(
        etcdctl \
            --endpoints="http://$cluster_to_join:2379" \
            member add "$(hostname)" \
            --learner=false \
            --peer-urls="http://$(hostname -i):2380"
    )

    initial_cluster=$(echo "$cluster_config" | grep "ETCD_INITIAL_CLUSTER=" | sed "s/ETCD_INITIAL_CLUSTER=//" | sed "s/\"//g")
    initial_cluster_state=$(echo "$cluster_config" | grep "ETCD_INITIAL_CLUSTER_STATE=" | sed "s/ETCD_INITIAL_CLUSTER_STATE=//" | sed "s/\"//g")

    log "Joining cluster with Initial Cluster [$initial_cluster] and Initial Cluster State [$initial_cluster_state]..."
    etcd \
        --initial-cluster             "$initial_cluster" \
        --initial-cluster-state       "$initial_cluster_state" \
        --name                        "$(hostname)" \
        --data-dir                    "$etcd_data_dir" \
        --initial-cluster-token       "$cluster-$role" \
        --listen-client-urls          "http://$(hostname -i):2379,http://127.0.0.1:2379" \
        --advertise-client-urls       "http://$(hostname -i):2379" \
        --listen-peer-urls            "http://$(hostname -i):2380" \
        --initial-advertise-peer-urls "http://$(hostname -i):2380"

else
    if [[ "$cluster_to_join" != "" && "$is_former_member" == "true" ]]; then
        log "Found a running etcd cluster of which this instance is a registered member.  Attempting to join it..."
    elif [[ "$cluster_to_join" == "" && "$(hostname -i)" == "$cold_starter" ]]; then
        log "Did not find a running cluster to join.  As the cold-starter, beginning to bootstrap a new cluster..."
    else
        fatal "Did not find a running cluster to join, and is not the cold-starter.  Exiting..."
    fi
    etcd \
        --name                        "$(hostname)" \
        --data-dir                    "$etcd_data_dir" \
        --initial-cluster-token       "$cluster-$role" \
        --listen-client-urls          "http://$(hostname -i):2379,http://127.0.0.1:2379" \
        --advertise-client-urls       "http://$(hostname -i):2379" \
        --listen-peer-urls            "http://$(hostname -i):2380" \
        --initial-advertise-peer-urls "http://$(hostname -i):2380"
fi
