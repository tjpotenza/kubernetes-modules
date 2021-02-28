#!/usr/bin/env bash
set -o errexit -o pipefail

public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
availability_zone=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

################################################################################
# File Templates
################################################################################
config_yaml="\
---
write-kubeconfig-mode: 0644
tls-san:
  - $public_ip
${control_plane_sans}
"

admin_yml=$(cat <<'CONFIG_FILE'
${admin_yml}
CONFIG_FILE
)

node_token_yml=$(cat <<'CONFIG_FILE'
${node_token_yml}
CONFIG_FILE
)

################################################################################
# Installation and Bootstrapping
################################################################################
sudo mkdir -p "/etc/rancher/k3s"
sudo echo "$config_yaml" > "/etc/rancher/k3s/config.yaml"

curl -sfL https://get.k3s.io | ${k3s_install_options} sh -s - --node-label="topology.kubernetes.io/zone=$availability_zone"

kubectl=$(which kubectl)
echo "$admin_yml" > "./admin.yml"
sudo $kubectl apply -f "./admin.yml"

echo "$node_token_yml" > "./node_token.yml"
sudo $kubectl apply -f "./node_token.yml"
