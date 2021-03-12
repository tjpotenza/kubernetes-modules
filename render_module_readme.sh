#!/usr/bin/env bash
set -o errexit -o pipefail

module_path="${1}"
inputs_template='"| `\(.name)` | \(.description) | `\( if has("type") then .type else "any" end )` | `\( if has("default") then .default else "n/a" end )` |"'
outputs_template='"| `\(.name)` | \(.description) |"'
resources_template='"* [\(.providerName)_\(.type)](https://registry.terraform.io/providers/\(.provicerSource)/\(.version)/docs/\( if .mode == "data" then "data-sources" else "resources" end )/\(.type)) (\( if .mode == "managed" then "resource" else .mode end ))"'
# Note the typo in "provicerSource"; that is how the value appears in the [ terraform-docs --json ] output itself.

if [[ "${module_path}" == "" || ! -d "${module_path}" ]]; then
    echo "[ERR] A valid module path is required." >&2
    exit 1
fi

if [[ ! -e "${module_path}/README.base.md" ]]; then
    echo "[ERR] No base README found at [${module_path}/README.base.md]." >&2
    exit 1
fi

which terraform-docs > "/dev/null" 2>&1 || {
    echo "[ERR] The [ terraform-docs ] cli tool is required." >&2
    exit 1
}

echo "[INFO] Rendering a module README file for [${module_path}]..." >&2
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
