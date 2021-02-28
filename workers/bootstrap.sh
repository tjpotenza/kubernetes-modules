#!/usr/bin/env bash
set -o errexit -o pipefail

availability_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

node_token="$( curl -sfL "http://${control_plane_address}:30000" )"
control_plane_address="https://${control_plane_address}:6443"

curl -sfL https://get.k3s.io | K3S_URL="$control_plane_address" K3S_TOKEN="$node_token" ${k3s_install_options} sh -s - --node-label="topology.kubernetes.io/zone=$availability_zone"
