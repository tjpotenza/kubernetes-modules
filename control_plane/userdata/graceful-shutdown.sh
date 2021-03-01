#!/usr/bin/env bash
set -o errexit -o pipefail

token=$(curl -sSLf "localhost:30000/token")
ca_crt=$(curl -sSLf "localhost:30000/ca.crt" | base64 -w0)
control_plane_address="https://${control_plane_address}:6443"

kubeconfig="
---
apiVersion: v1
kind: Config
users:
- name: self
  user:
    token: $token
clusters:
- cluster:
    certificate-authority-data: $ca_crt
    server: $control_plane_address
  name: self
contexts:
- context:
    cluster: self
    user: self
  name: self
current-context: self
"

# Weirdly --grace-period only accepts an integer number of seconds without units, while --timeout only accepts a duration featuring a unit.
kubectl --kubeconfig=<(echo "$kubeconfig") drain "$(hostname)" --force="true" --ignore-daemonsets="true" --grace-period="180" --timeout="360s"
kubectl --kubeconfig=<(echo "$kubeconfig") delete "nodes/$(hostname)"
