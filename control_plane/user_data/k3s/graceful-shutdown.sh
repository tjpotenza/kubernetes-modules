#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

log "Retrieving kubectl credentials from control-plane..."
token=$(curl -sSLf "localhost:30000/token")
ca_crt=$(curl -sSLf "localhost:30000/ca.crt" | base64 -w0)
control_plane_address="https://control-plane.cluster.local:6443"

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

log "Draining pods from self..."
# Weirdly --grace-period only accepts an integer number of seconds without units, while --timeout only accepts a duration featuring a unit.
/usr/local/bin/kubectl drain "$(hostname)" \
    --kubeconfig=<(echo "$kubeconfig") \
    --force="true" \
    --ignore-daemonsets="true" \
    --delete-emptydir-data \
    --grace-period="180" \
    --timeout="360s"

log "Removing self from cluster..."
/usr/local/bin/kubectl --kubeconfig=<(echo "$kubeconfig") delete "nodes/$(hostname)"
