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
graceful_shutdown_sh=$(      echo "${graceful_shutdown_sh}"      | base64 -d )
graceful_shutdown_service=$( echo "${graceful_shutdown_service}" | base64 -d )
admin_yaml=$(                echo "${admin_yaml}"                | base64 -d )
worker_bootstrapper_yaml=$(  echo "${worker_bootstrapper_yaml}"  | base64 -d )
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

####################################################################################################
# Control-Plane: Mounting Any Extra EBS Volumes (WIP)
####################################################################################################
# retries="6"
# interval="10"
# data_volume="/dev/sdf"
# mount_point="/var/lib/rancher/k3s"

# log "Checking whether a mounted volume exists at [$data_volume]..."
# for i in $(seq "$retries"); do
#     [[ -e "$data_volume" ]] && {
#         additional_volume_exists="true"
#         break
#     } || {
#         log "- Attempt $i/$retries: No volume found at [$data_volume]."
#     }
#     sleep "$interval"
# done

# if [[ "$additional_volume_exists" == "true" ]]; then
#     if [[ "$( lsblk -f -n -o FSTYPE "$data_volume" )" == "" ]]; then
#         log "Unformatted drive found at [$data_volume], formatting it..."
#         sudo mkfs -t xfs "$data_volume"
#     fi

#     log "Retrieving UUID for [$data_volume]..."
#     uuid=$(lsblk -n -o UUID "$data_volume")

#     log "Mounting [$data_volume] to [$mount_point]..."
#     echo "UUID=$uuid  $mount_point  xfs  defaults,nofail  0  2" | sudo tee -a "/etc/fstab" > "/dev/null"

# else
#     log "No additional volume found, using root file system."
# fi

# log "Creating k3s data directory at [$mount_point], and mounting all volumes..."
# sudo mkdir -p "$mount_point"
# sudo mount -a

####################################################################################################
# Control-Plane: Installing Kubernetes itself
####################################################################################################
log "Writing K3S config file..."
sudo mkdir -p "/etc/rancher/k3s"
echo "$config_yaml" | sudo tee "/etc/rancher/k3s/config.yaml" > "/dev/null"

log "Installing K3S..."
curl -sfL https://get.k3s.io | ${k3s_install_options} sh -s - \
    --node-label "topology.kubernetes.io/zone=$availability_zone" $k3s_options

####################################################################################################
# Control-Plane: Installing standard manifests
####################################################################################################
log "Installing standard manifests..."
kubectl=$(which kubectl)
echo "$admin_yaml" > "./admin.yaml"
sudo $kubectl apply -f "./admin.yaml"

echo "$worker_bootstrapper_yaml" > "./worker-bootstrapper.yaml"
sudo $kubectl apply -f "./worker-bootstrapper.yaml"

####################################################################################################
# Shared: The systemd unit that triggers a node to drain and remove itself on shutdown
####################################################################################################
log "Installing graceful-shutdown.sh..."
echo "$graceful_shutdown_sh" | sudo tee "/usr/local/bin/graceful-shutdown.sh" > "/dev/null"
sudo chmod 0755 "/usr/local/bin/graceful-shutdown.sh"

log "Installing graceful-shutdown.service..."
echo "$graceful_shutdown_service" | sudo tee "/etc/systemd/system/graceful-shutdown.service" > "/dev/null"
sudo systemctl daemon-reload
sudo systemctl enable graceful-shutdown.service --now
