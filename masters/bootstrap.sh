#!/usr/bin/env bash
set -o errexit -o pipefail

public_ip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

admin_serviceaccount_yaml="\
---
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: default
  name: admin
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    namespace: default
    name: admin
"

config_yaml="\
---
write-kubeconfig-mode: 0644
tls-san:
  - ${master_address}
  - $public_ip
"

sudo mkdir -p "/etc/rancher/k3s"
sudo echo "$config_yaml" > "/etc/rancher/k3s/config.yaml"

curl -sfL https://get.k3s.io | sh -

kubectl=$(which kubectl)
echo "$admin_serviceaccount_yaml" > "./admin_serviceaccount.yaml"
sudo $kubectl apply -f "./admin_serviceaccount.yaml"
