#!/usr/bin/env bash
set -o errexit -o pipefail

####################################################################################################
# Worker: Frontloading Terraform template values and EC2 metadata values into bash vars
####################################################################################################
control_plane_address=$(     echo "${control_plane_address}"     | base64 -d )

public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
availability_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

####################################################################################################
# Worker: Installing Kubernetes itself
####################################################################################################
node_token="$( curl -sfL "http://$control_plane_address:30000/node-token" )"
cluster_api_endpoint="https://$control_plane_address:6443"

curl -sfL https://get.k3s.io | K3S_URL="$cluster_api_endpoint" K3S_TOKEN="$node_token" ${k3s_install_options} sh -s - --node-label="topology.kubernetes.io/zone=$availability_zone"