#!/usr/bin/env bash
set -o errexit -o pipefail

current_path=$( builtin cd "$(dirname "${BASH_SOURCE[0]}")" > "/dev/null" 2>&1; pwd )
source "${current_path}/lib/cli.sh"

################################################################################
# Check parameters and set defaults for overrideable values
################################################################################

description="
NAME
    generate_kubeconfig - Given a cluster name, attempts to look it up and
                          generate a local kubeconfig for accessing it.

SYNOPSIS
    generate_kubeconfig.sh [-h|--help]
    generate_kubeconfig.sh <cluster_name>

DESCRIPTION
    A number of standard values can be overridden; check the script below this
    description to see them and their default values.  Looks up an instance of
    the cluster's control plane by tags on the instance, then attempts to
    generate a kubeconfig using that instance's 'kubectl' over SSH.  Requires
    that an 'admin' SA be created and bound the appropriate ClusterRole, and
    that the Control Planes have their default super-user kubectl access for
    now.

    At the time of writing, this tool looks up the public IP of a Control
    Plane instance; if that instance gets rotated away or replaced, this tool
    may be re-run to generate a new kubeconfig that features an updated IP.

OUTPUT
    * Returns 0 and prints the kubeconfig to 'stdout' on success.
    * Returns 1 and prints status messages to 'stderr' if any issues occur.
"

################################################################################
# Check parameters and set defaults for overrideable values
################################################################################

cluster_name="${1}"
if [[ "${cluster_name}" == "" ]]; then
    log fatal "A cluster name must be provided."
fi

if [[ "${cluster_name}" == "-h" || "${cluster_name}" == "--help" ]]; then
    printf "%s\n" "$description"
    exit 0
fi

[[ -z "${REGION}" ]]      && REGION="us-east-1"
[[ -z "${SSH}" ]]         && SSH="ssh"
[[ -z "${SSH_USER}" ]]    && SSH_USER="ec2-user"
[[ -z "${SSH_KUBECTL}" ]] && SSH_KUBECTL="sudo /usr/local/bin/kubectl"
[[ -z "${SA_NAME}" ]]     && SA_NAME="admin"
[[ -z "${FORCE_COLOR}" ]] && FORCE_COLOR="true"

################################################################################
# Find a master address (currently one of the nodes' public ips)
################################################################################

log info "Looking up details for a master instance from cluster [${cluster_name}]..."
control_plane_instance_ip=$(
    aws ec2 describe-instances \
        --region="${REGION}" \
        --output="json" \
        --filters \
            "Name=tag:Cluster,Values=${cluster_name}" \
            "Name=tag:Role,Values=control-plane" \
            "Name=instance-state-name,Values=running" \
    | jq ".Reservations[].Instances[].PublicIpAddress" -rec | sort -R | head -n1
) || {
    log fatal "Unable to find instances for cluster [${cluster_name}] in region [${REGION}].  Make sure the cluster name, the AWS region, and the AWS account are correct."
}

################################################################################
# Use that instance's kubectl via SSH to retrieve SA credentials
################################################################################

# kubectl="${SSH} -oStrictHostKeyChecking=accept-new -oUserKnownHostsFile="/dev/null" ${SSH_USER}@${control_plane_instance_ip} ${SSH_KUBECTL}"
kubectl="${SSH} -oStrictHostKeyChecking=accept-new -oUserKnownHostsFile="/dev/null" -oLogLevel="QUIET" ${SSH_USER}@${control_plane_instance_ip} ${SSH_KUBECTL}"

log info "Retrieving name of secrets attached to serviceaccount [${SA_NAME}] from [${control_plane_instance_ip}]..."
    serviceaccount_secret_names=$(
        $kubectl --namespace "default" --output "json" get serviceaccounts/${SA_NAME} | jq '.secrets[].name' -rec
    ) || {
        log fatal "Failed when retrieving the [${SA_NAME}] serviceaccount.  This may be because the [${SA_NAME}] serviceaccount has not been created as expected."
    }

log info "Retrieving secrets for serviceaccount [${SA_NAME}]..."
    serviceaccount_secret=$(
        # I've seen a weird fringe edge case where the serviceaccount had multiple secret names in .secrets, however only one of them actually existed.
        # This iteration and error-swallowing is to ensure we get the right secret data, even if there are multiple secret names returned.
        for serviceaccount_secret_name in ${serviceaccount_secret_names[@]}; do
            $kubectl --namespace "default" --output "json" get "secrets/$serviceaccount_secret_name" 2> "/dev/null"
        done
    ) || true
    if [[ "$serviceaccount_secret" == "" ]]; then
        log fatal "Failed when retrieving the serviceaccount secrets for [${SA_NAME}].  This *should* never happen, so doublecheck no new RBAC rules have been established and make sure the serviceaccount is configured correctly."
    fi

log info "Extracting serviceaccount token from serviceaccount secret..."
    serviceaccount_token=$(
        printf "%s" "$serviceaccount_secret" | jq '.data["token"]' -rec | base64 -D
    ) || {
        log fatal "An error occurred while extracting the token from the [${SA_NAME}] serviceaccount."
    }

log info "Extracting serviceaccount certificate from serviceaccount secret..."
    serviceaccount_cert=$(
        printf "%s" "$serviceaccount_secret" | jq '.data["ca.crt"]' -rec # We leave the cert base64 encoded in a kubeconfig
    ) || {
        log fatal "An error occurred while extracting the cert from the [${SA_NAME}] serviceaccount."
    }

################################################################################
# Actually render a kubeconfig file for the cluster using the above values
################################################################################

kubeconfig="\
---
apiVersion: v1
kind: Config
users:
- name: ${cluster_name}
  user:
    token: ${serviceaccount_token}
clusters:
- cluster:
    certificate-authority-data: ${serviceaccount_cert}
    server: https://${control_plane_instance_ip}:6443
  name: ${cluster_name}
contexts:
- context:
    cluster: ${cluster_name}
    user: ${cluster_name}
  name: ${cluster_name}
current-context: ${cluster_name}
"

echo "${kubeconfig}"

log info "Successfully rendered a kubeconfig for cluster [${cluster_name}]!"
if [[ "${is_a_tty}" == "true" ]]; then
    log warn "This script was designed for its output to be piped to another process or redirected into a file, such as with [$(styled "cyan" "generate_kubeconfig.sh clusterName > kubeconfig.yml")]."
fi
