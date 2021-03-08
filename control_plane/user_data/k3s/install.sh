#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

####################################################################################################
# Control-Plane: Frontloading Terraform template values and EC2 metadata values into bash vars
####################################################################################################
log "Loading values populated by Terraform..."
k3s_options=$(               echo "${k3s_options}"               | base64 -d )
control_plane_sans=$(        echo "${control_plane_sans}"        | base64 -d )

log "Loading values from EC2 Metadata API..."
public_ip=$(curl -sSfL http://169.254.169.254/latest/meta-data/public-ipv4)
availability_zone=$(curl -sSfL http://169.254.169.254/latest/meta-data/placement/availability-zone)

####################################################################################################
# Control-Plane: File Templates
####################################################################################################
config_yaml="\
---
write-kubeconfig-mode: 0644
tls-san: [ $public_ip, $control_plane_sans ]
"
###################################################################################################
# Control-Plane: Installing Kubernetes itself
####################################################################################################
log "Writing K3S config file..."
sudo mkdir -p "/etc/rancher/k3s"
echo "$config_yaml" | sudo tee "/etc/rancher/k3s/config.yaml" > "/dev/null"

log "Installing K3S..."
curl -sfL https://get.k3s.io | ${k3s_install_options} sh -s - \
    --node-label "topology.kubernetes.io/zone=$availability_zone" $k3s_options \
    --datastore-endpoint "http://localhost:2379"
