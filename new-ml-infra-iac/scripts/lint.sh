set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <module-path>"
  exit 1
fi

module_path="$1"
main_file="${module_path}/main.bicep"

if [[ ! -f "$main_file" ]]; then
  echo "ERROR: main.bicep not found at: $main_file"
  exit 1
fi

echo "Linting module: $module_path"
az bicep lint --file "$main_file"
echo "Lint succeeded: $module_path"
