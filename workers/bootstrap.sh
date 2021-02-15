#!/usr/bin/env bash
set -o errexit -o pipefail

node_token="$( curl -sfL "http://${control_plane_address}:30000" )"
control_plane_address="https://${control_plane_address}:6443"

curl -sfL https://get.k3s.io | K3S_URL="$control_plane_address" K3S_TOKEN="$node_token" ${k3s_install_options} sh -
