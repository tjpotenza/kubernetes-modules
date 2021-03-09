#!/usr/bin/env bash
set -o errexit -o pipefail

sudo yum update -y
sudo yum install -y jq

####################################################################################################
# Worker: Frontloading Terraform template values and EC2 metadata values into bash vars
####################################################################################################
# control_plane_address=$( echo "${control_plane_address}" | base64 -d )
control_plane_address="control-plane.cluster.local"

public_ip=$(         curl -sSLf http://169.254.169.254/latest/meta-data/public-ipv4 )
availability_zone=$( curl -sSLf http://169.254.169.254/latest/meta-data/placement/availability-zone )

####################################################################################################
# Worker: Installing Kubernetes itself
####################################################################################################
sudo /usr/local/lib/k3s/discover-control-plane.sh
node_token="$( curl -sfL "http://$control_plane_address:30000/node-token" )"
cluster_api_endpoint="https://$control_plane_address:6443"

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
