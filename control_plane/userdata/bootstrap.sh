#!/usr/bin/env bash
set -o errexit -o pipefail

####################################################################################################
# Control-Plane: Frontloading Terraform template values and EC2 metadata values into bash vars
####################################################################################################
graceful_shutdown_sh=$(      echo "${graceful_shutdown_sh}"      | base64 -d )
graceful_shutdown_service=$( echo "${graceful_shutdown_service}" | base64 -d )
admin_yaml=$(                echo "${admin_yaml}"                 | base64 -d )
worker_bootstrapper_yaml=$(  echo "${worker_bootstrapper_yaml}"   | base64 -d )
control_plane_sans=$(        echo "${control_plane_sans}"        | base64 -d )

public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
availability_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

####################################################################################################
# Control-Plane: File Templates
####################################################################################################
config_yaml="\
---
write-kubeconfig-mode: 0644
tls-san: [ $public_ip, $control_plane_sans ]
"

####################################################################################################
# Control-Plane: Installing Kubernetes itself
####################################################################################################
sudo mkdir -p "/etc/rancher/k3s"
echo "$config_yaml" | sudo tee "/etc/rancher/k3s/config.yaml" > "/dev/null"

curl -sfL https://get.k3s.io | ${k3s_install_options} sh -s - --node-label="topology.kubernetes.io/zone=$availability_zone"

####################################################################################################
# Control-Plane: Installing standard manifests
####################################################################################################
kubectl=$(which kubectl)
echo "$admin_yaml" > "./admin.yaml"
sudo $kubectl apply -f "./admin.yaml"

echo "$worker_bootstrapper_yaml" > "./worker-bootstrapper.yaml"
sudo $kubectl apply -f "./worker-bootstrapper.yaml"


####################################################################################################
# Shared: The systemd unit that triggers a node to drain and remove itself on shutdown
####################################################################################################
echo "$graceful_shutdown_sh" | sudo tee "/usr/local/bin/graceful-shutdown.sh" > "/dev/null"
sudo chmod 0755 "/usr/local/bin/graceful-shutdown.sh"

echo "$graceful_shutdown_service" | sudo tee "/etc/systemd/system/graceful-shutdown.service" > "/dev/null"
sudo systemctl daemon-reload
sudo systemctl enable graceful-shutdown.service --now
