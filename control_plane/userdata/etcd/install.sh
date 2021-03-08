#!/usr/bin/env bash
set -o errexit -o pipefail

function log()   { echo "[INFO] $1" >&2; }
function warn()  { echo "[WARN] $1" >&2; }
function err()   { echo "[ERR] $1" >&2; }
function fatal() { echo "[ERR] $1" >&2; exit 1; }

etcd_version="${etcd_version}"
etcd_data_dir="/var/lib/etcd"

####################################################################################################
# Install etcd
####################################################################################################
sudo yum update -y
sudo yum install -y jq

etcd_download_url="https://storage.googleapis.com/etcd"
etcd_download_dir="/run/etcd"

mkdir -p "$etcd_download_dir"
mkdir -p "$etcd_data_dir"

curl \
    -L "$etcd_download_url/$etcd_version/etcd-$etcd_version-linux-amd64.tar.gz" \
    -o "$etcd_download_dir/etcd-$etcd_version-linux-amd64.tar.gz"

tar xzvf \
    "$etcd_download_dir/etcd-$etcd_version-linux-amd64.tar.gz" \
    -C "$etcd_download_dir" --strip-components=1

mv "$etcd_download_dir/etcd" "/usr/bin/"
mv "$etcd_download_dir/etcdctl" "/usr/bin/"
rm -rf "$etcd_download_dir"
