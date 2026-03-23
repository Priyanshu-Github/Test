#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <modules-root> <acr-name> [target-branch-ref]"
  exit 1
fi

modules_root="${1%/}"
acr_name="$2"
target_branch_ref="${3:-${TARGET_BRANCH:-}}"
changed_modules_file="${CHANGED_MODULES_FILE:-/tmp/changed-modules.json}"

if [[ ! -d "$modules_root" ]]; then
  echo "ERROR: Modules root not found: $modules_root"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not found."
  exit 1
fi

declare -A changed_code_modules=()
declare -A seen_publish_modules=()
declare -A tags_cache=()
declare -A tags_loaded=()
summary_rows=()
changed_json='[]'

escape_ado() {
  local value="$1"
  value="${value//'%'/'%AZP25'}"
  value="${value//$'\n'/'%0A'}"
  value="${value//$'\r'/'%0D'}"
  printf '%s' "$value"
}

add_summary() {
  local name="$1"
  local version="$2"
  local status="$3"
  local row="${name}|${version}|${status}"
  local existing

  for existing in "${summary_rows[@]}"; do
    if [[ "$existing" == "$row" ]]; then
      return
    fi
  done

  summary_rows+=("${name}|${version}|${status}")
}

add_publish_candidate() {
  local name="$1"
  local version="$2"
  local path="$3"

  if [[ -n "${seen_publish_modules[$name]:-}" ]]; then
    return
  fi

  changed_json="$(jq -c \
    --arg name "$name" \
    --arg version "$version" \
    --arg path "$path" \
    '. + [{name:$name, version:$version, path:$path}]' <<<"$changed_json")"
  seen_publish_modules["$name"]=1
}

normalize_target_ref() {
  local ref="$1"

  if [[ -z "$ref" ]]; then
    printf '%s' ""
    return
  fi

  if [[ "$ref" =~ ^\$\(.+\)$ ]]; then
    printf '%s' ""
    return
  fi

  if [[ "$ref" == refs/heads/* ]]; then
    printf '%s' "origin/${ref#refs/heads/}"
    return
  fi

  if [[ "$ref" == origin/* ]]; then
    printf '%s' "$ref"
    return
  fi

  printf '%s' "origin/$ref"
}

get_acr_tags() {
  local module_name="$1"

  if [[ -n "${tags_loaded[$module_name]:-}" ]]; then
    printf '%s' "${tags_cache[$module_name]}"
    return 0
  fi

  local output
  if output="$(az acr repository show-tags \
      --name "$acr_name" \
      --repository "bicep/modules/${module_name}" \
      --output tsv 2>&1)"; then
    tags_cache["$module_name"]="$output"
    tags_loaded["$module_name"]=1
    printf '%s' "$output"
    return 0
  fi

  if [[ "$output" == *"RepositoryNotFound"* || "$output" == *"NAME_UNKNOWN"* || "$output" == *"repository not found"* || "$output" == *"does not exist"* ]]; then
    tags_cache["$module_name"]=""
    tags_loaded["$module_name"]=1
    printf ''
    return 0
  fi

  echo "ERROR: Failed to query ACR tags for module '${module_name}'."
  echo "$output"
  exit 1
}

version_exists_in_acr() {
  local module_name="$1"
  local version="$2"
  local tags

  tags="$(get_acr_tags "$module_name")"
  while IFS= read -r tag; do
    if [[ "$tag" == "$version" ]]; then
      return 0
    fi
  done <<<"$tags"

  return 1
}

read_metadata_field() {
  local metadata_file="$1"
  local jq_expr="$2"
  jq -er "$jq_expr" "$metadata_file" 2>/dev/null
}

validate_module_metadata() {
  local module_path="$1"
  local metadata_file="${module_path}/metadata.json"
  local module_dir
  local name
  local version

  module_dir="$(basename "$module_path")"

  if [[ ! -f "$metadata_file" ]]; then
    echo "ERROR: Missing metadata.json for module: $module_dir"
    exit 1
  fi

  name="$(read_metadata_field "$metadata_file" '.name')" || {
    echo "ERROR: Invalid metadata.json (.name) for module: $module_dir"
    exit 1
  }
  version="$(read_metadata_field "$metadata_file" '.version')" || {
    echo "ERROR: Invalid metadata.json (.version) for module: $module_dir"
    exit 1
  }

  if [[ "$name" != "$module_dir" ]]; then
    echo "ERROR: Module folder '$module_dir' does not match metadata name '$name'."
    exit 1
  fi

  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid SemVer '$version' in ${metadata_file}."
    exit 1
  fi

  printf '%s|%s' "$name" "$version"
}

collect_code_changed_modules() {
  local diff_target="$1"
  local changed_files

  if [[ -n "$diff_target" ]]; then
    changed_files="$(git diff "$diff_target" --name-only -- "${modules_root}/" || true)"
  else
    changed_files=""
  fi

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ "$file" != "${modules_root}/"* ]] && continue
    [[ "$file" != *.bicep ]] && continue

    local rel_path module_name
    rel_path="${file#${modules_root}/}"
    module_name="${rel_path%%/*}"
    [[ -n "$module_name" ]] && changed_code_modules["$module_name"]=1
  done <<<"$changed_files"
}

determine_diff_target() {
  local normalized_target

  normalized_target="$(normalize_target_ref "$target_branch_ref")"
  if [[ -n "$normalized_target" ]]; then
    local branch_name
    branch_name="${normalized_target#origin/}"

    if ! git rev-parse --verify "$normalized_target" >/dev/null 2>&1; then
      git fetch origin "$branch_name" >/dev/null 2>&1 || true
    fi

    if git rev-parse --verify "$normalized_target" >/dev/null 2>&1; then
      printf '%s' "${normalized_target}...HEAD"
      return
    fi
  fi

  if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    printf '%s' "HEAD~1"
    return
  fi

  printf '%s' ""
}

print_summary() {
  echo "Module Version Summary"
  printf '%-28s %-12s %-20s\n' "MODULE" "VERSION" "STATUS"
  printf '%-28s %-12s %-20s\n' "------" "-------" "------"

  for row in "${summary_rows[@]}"; do
    IFS='|' read -r name version status <<<"$row"
    printf '%-28s %-12s %-20s\n' "$name" "$version" "$status"
  done
}

main() {
  local diff_target
  local module_name
  local module_path
  local metadata_pair
  local metadata_name
  local metadata_version
  diff_target="$(determine_diff_target)"

  if [[ -n "$diff_target" ]]; then
    echo "Using diff target: $diff_target"
  else
    echo "No previous commit/target branch available; skipping Phase 1 git-diff governance check."
  fi

  collect_code_changed_modules "$diff_target"

  # Phase 1: enforce version governance for code-changed modules.
  for module_name in "${!changed_code_modules[@]}"; do
    module_path="${modules_root}/${module_name}"

    if [[ ! -d "$module_path" ]]; then
      continue
    fi

    metadata_pair="$(validate_module_metadata "$module_path")"
    metadata_name="${metadata_pair%%|*}"
    metadata_version="${metadata_pair##*|}"

    if version_exists_in_acr "$metadata_name" "$metadata_version"; then
      add_summary "$metadata_name" "$metadata_version" "exists -> fail"
      print_summary
      echo "ERROR: Module '${metadata_name}' has code changes but version '${metadata_version}' already exists in ACR."
      echo "Bump the version in ${module_path}/metadata.json before merging."
      exit 1
    fi

    add_publish_candidate "$metadata_name" "$metadata_version" "$module_path"
    add_summary "$metadata_name" "$metadata_version" "new -> publish"
  done

  # Phase 2: scan all modules to catch version-only bumps and enforce metadata quality.
  for module_path in "${modules_root}"/*; do
    [[ -d "$module_path" ]] || continue

    metadata_pair="$(validate_module_metadata "$module_path")"
    metadata_name="${metadata_pair%%|*}"
    metadata_version="${metadata_pair##*|}"

    if version_exists_in_acr "$metadata_name" "$metadata_version"; then
      add_summary "$metadata_name" "$metadata_version" "exists -> skip"
      continue
    fi

    add_publish_candidate "$metadata_name" "$metadata_version" "$module_path"
    add_summary "$metadata_name" "$metadata_version" "new -> publish"
  done

  printf '%s\n' "$changed_json" >"$changed_modules_file"
  print_summary

  local changed_count has_changes escaped_json
  changed_count="$(jq -r 'length' <<<"$changed_json")"
  if [[ "$changed_count" -gt 0 ]]; then
    has_changes="true"
  else
    has_changes="false"
  fi

  escaped_json="$(escape_ado "$changed_json")"

  echo "Detected modules to publish: $changed_count"
  echo "Changed modules file: $changed_modules_file"
  echo "##vso[task.setvariable variable=changedModules;isOutput=true]$escaped_json"
  echo "##vso[task.setvariable variable=hasChanges;isOutput=true]$has_changes"
  echo "##vso[task.setvariable variable=changedCount;isOutput=true]$changed_count"
}

main
