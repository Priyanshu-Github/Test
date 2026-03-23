#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <module-path> <module-name> <version> <acr-name>"
  exit 1
fi

module_path="$1"
module_name="$2"
module_version="$3"
acr_name="$4"
main_file="${module_path}/main.bicep"
target_ref="br:${acr_name}.azurecr.io/bicep/modules/${module_name}:${module_version}"

if [[ ! -f "$main_file" ]]; then
  echo "ERROR: main.bicep not found at: $main_file"
  exit 1
fi

echo "Publishing module: ${module_name}:${module_version}"
az bicep publish \
  --file "$main_file" \
  --target "$target_ref"
