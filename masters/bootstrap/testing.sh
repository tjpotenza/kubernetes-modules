#!/usr/bin/env bash
set -o errexit -o pipefail

admin_yml=$(cat <<'CONFIG_FILE'
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

CONFIG_FILE
)

echo "admin.yml:"
echo "--------------------------------------------------------------------------------"
echo "${admin_yml}"
echo "--------------------------------------------------------------------------------"
