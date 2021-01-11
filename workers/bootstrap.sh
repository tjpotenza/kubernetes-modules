#!/usr/bin/env bash
set -o errexit -o pipefail

node_token="$( curl -sfL "https://${node_token_address}" )"
master_address="https://${master_address}:6443"

curl -sfL https://get.k3s.io | K3S_URL="$master_address" K3S_TOKEN="$node_token" sh -
