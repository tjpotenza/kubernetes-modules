#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

log "Updating packages and installing jq..."
sudo yum update -y
sudo yum install -y jq

####################################################################################################
# Worker: Frontloading Terraform template values and EC2 metadata values into bash vars
####################################################################################################
control_plane_address="control-plane.cluster.local"
cluster_api_endpoint="https://$control_plane_address:6443"
node_token=""

log "Pulling instance details from EC2 Metadata api..."
public_ip=$(         curl -sSLf http://169.254.169.254/latest/meta-data/public-ipv4 )
availability_zone=$( curl -sSLf http://169.254.169.254/latest/meta-data/placement/availability-zone )

####################################################################################################
# Worker: Installing Kubernetes itself
####################################################################################################
log "Attempting to pull bootstrapping metadata from control plane..."
attempts="10"
interval="60"
for i in $(seq "$attempts"); do
    log "Discovering a valid Control Plane address..."
    sudo /usr/local/lib/k3s/discover-control-plane.sh

    node_token=$( curl -sfL "http://$control_plane_address:30000/node-token" ) && {
        log "Successfully retrieved bootstrapping metadata from control plane."
        break
    } || {
        warn "Unable to reach the control plane on attempt $i/$attempts.  Retrying..."
        sleep "$interval"
    }
done

if [[ "$node_token" == "" ]]; then
    fatal "Unable to reach the control plane after $attempts * $interval seconds.  Assuming it is unavailable and giving up."
fi

curl -sfL https://get.k3s.io | ${k3s_install_options} \
    K3S_TOKEN="$node_token" \
    K3S_URL="$cluster_api_endpoint" \
    INSTALL_K3S_SKIP_START="true" \
    INSTALL_K3S_SKIP_ENABLE="true" \
    sh -s - \
    --node-label="topology.kubernetes.io/zone=$availability_zone" ${k3s_options}

echo "ExecStartPre=/usr/local/lib/k3s/discover-control-plane.sh" | sudo tee -a "/etc/systemd/system/k3s-agent.service" > "/dev/null"
sudo systemctl daemon-reload
sudo systemctl enable k3s-agent --now
