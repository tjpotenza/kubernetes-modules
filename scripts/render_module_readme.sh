#!/usr/bin/env bash
set -o errexit -o pipefail

current_path=$( builtin cd "$(dirname "${BASH_SOURCE[0]}")" > "/dev/null" 2>&1; pwd )
source "${current_path}/lib/cli.sh"

description="
NAME
    render_module_readme - Given a module directory, renders a README.md

SYNOPSIS
    render_module_readme.sh [-h|--help]
    render_module_readme.sh <path_to_module>

DESCRIPTION
    Given a module, will render a more human-readable README.md from its
    variables, outputs and resources used.  A [README.base.md] is expected
    in each directory, and will be the first section of the rendered output.

    Full disclaimer; this is a super janky script I hacked together to help
    with creating README's for each module.  If I continue to develop and
    expand these modules, I'll definitely look to build something a bit
    more durable and sophisticated.  Pretty much all the heavy lifting for
    this script's handled by the [ terraform-docs ] CLI tool, anywho:
        https://terraform-docs.io/

    Depends on both [jq] and [terraform-docs], both of which are available
    to be installed with [brew].

OUTPUT
    * Returns 0 and prints the rendered README.md to 'stdout' on success.
    * Returns 1 and prints status messages to 'stderr' if any issues occur.
"

inputs_template='"| `\(.name)` | \(.description) | `\( if has("type") then .type else "any" end )` | `\( if has("default") then .default else "n/a" end )` |"'
outputs_template='"| `\(.name)` | \(.description) |"'
resources_template='"* [\(.providerName)_\(.type)](https://registry.terraform.io/providers/\(.provicerSource)/\(.version)/docs/\( if .mode == "data" then "data-sources" else "resources" end )/\(.type)) (\( if .mode == "managed" then "resource" else .mode end ))"'

################################################################################
# Check parameters and render the README contents
################################################################################

module_path="${1}"
if [[ "${module_path}" == "" || "${module_path}" == "-h" || "${module_path}" == "--help" ]]; then
    printf "%s\n" "$description"
    exit 0
fi
# Note the typo in "provicerSource"; that is how the value appears in the [ terraform-docs --json ] output itself.

if [[ "${module_path}" == "" || ! -d "${module_path}" ]]; then
    log fatal "A valid module path is required."
fi

if [[ ! -e "${module_path}/README.base.md" ]]; then
    log fatal "No base README found at [${module_path}/README.base.md]."
fi

which terraform-docs > "/dev/null" 2>&1 || {
    log fatal "The [ terraform-docs ] cli tool is required."
}

log info "Rendering a module README file for [${module_path}]..."
echo "\
$(cat "${module_path}/README.base.md")

## Variable Reference
| Name | Description | Type | Default |
|------|-------------|------|---------|
$(terraform-docs json "${module_path}" --sort="false" | jq ".inputs[] | ${inputs_template}" -rec)

## Output Reference
| Name | Description |
|------|-------------|
$(terraform-docs json "${module_path}" --sort="false" | jq ".outputs[] | ${outputs_template}" -rec)

## Resources and Data Sources Used
$(terraform-docs json "${module_path}" --sort="false" | jq ".resources[] | ${resources_template}" -rec)
"
