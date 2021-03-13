#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

cluster="${cluster}"
role_to_discover="control-plane"
control_plane_address="control-plane.cluster.local"

log "Looking up a control-plane instance ip..."
region=$( curl -sSLf "http://169.254.169.254/latest/dynamic/instance-identity/document" | jq ".region" -rec )
control_plane_instance_ip=$(
    aws ec2 describe-instances \
        --region="$region" \
        --output="json" \
        --filters \
            "Name=tag:Cluster,Values=$cluster" \
            "Name=tag:Role,Values=$role_to_discover" \
            "Name=instance-state-name,Values=running" \
    | jq ".Reservations[].Instances[].PrivateIpAddress" -rec | sort -R | head -n1
)

etc_hosts_line="$control_plane_instance_ip   $control_plane_address"

grep "$control_plane_address" "/etc/hosts" > "/dev/null" 2>&1 && {
    log "Updating existing [$control_plane_address] entry in /etc/hosts to [$etc_hosts_line]..."
    sudo sed -i -E "s/.*$control_plane_address\$/$etc_hosts_line/" "/etc/hosts"
} || {
    log "Adding new entry in /etc/hosts for [$etc_hosts_line]..."
    echo "$etc_hosts_line" | sudo tee -a "/etc/hosts" > "/dev/null"
}

log "Successfully updated /etc/hosts with entry [$etc_hosts_line]."
