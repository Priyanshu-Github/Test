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

# Defensive check: verify the version does not already exist in ACR.
existing_tags=""
if existing_tags="$(az acr repository show-tags \
    --name "$acr_name" \
    --repository "bicep/modules/${module_name}" \
    --output tsv 2>&1)"; then
  while IFS= read -r tag; do
    if [[ "$tag" == "$module_version" ]]; then
      echo "ERROR: Version '${module_version}' already exists in ACR for module '${module_name}'."
      echo "This may indicate a race condition or stale pipeline run. Aborting publish."
      exit 1
    fi
  done <<<"$existing_tags"
else
  # Repository not found in ACR — this is expected for first-time publishes.
  if [[ "$existing_tags" == *"RepositoryNotFound"* || "$existing_tags" == *"NAME_UNKNOWN"* || "$existing_tags" == *"not found"* || "$existing_tags" == *"does not exist"* ]]; then
    echo "Repository not found in ACR — first-time publish for module '${module_name}'."
  else
    echo "ERROR: Failed to query ACR tags for module '${module_name}'."
    echo "$existing_tags"
    exit 1
  fi
fi

echo "Publishing module: ${module_name}:${module_version}"
az bicep publish \
  --file "$main_file" \
  --target "$target_ref"
echo "Publish succeeded: ${module_name}:${module_version}"
