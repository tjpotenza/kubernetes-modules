#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

log "Looking up current instance's member ID..."
member_id=$(
    /usr/local/bin/etcdctl --endpoints="http://localhost:2379" member list -wsimple \
    | grep "$(hostname)," \
    | sed -E "s/,.*//"
)

log "Gracefully removing self (member_id: [$member_id]) from cluster..."
/usr/local/bin/etcdctl --endpoints="http://localhost:2379" member remove "$member_id"
