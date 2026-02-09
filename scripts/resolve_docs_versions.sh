#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: resolve_docs_versions.sh --repository <owner/repo> --manifest-path <path> [options]

Options:
  --max-versions <n>     Maximum number of release versions in dropdown (default: 5)
  --github-token <token> GitHub token (defaults to GITHUB_TOKEN env var)
  --github-output <path> Optional GitHub output file path
EOF
}

repository=""
manifest_path=""
max_versions=5
github_token="${GITHUB_TOKEN:-}"
github_output=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repository)
      repository="${2:-}"
      shift 2
      ;;
    --manifest-path)
      manifest_path="${2:-}"
      shift 2
      ;;
    --max-versions)
      max_versions="${2:-}"
      shift 2
      ;;
    --github-token)
      github_token="${2:-}"
      shift 2
      ;;
    --github-output)
      github_output="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "${repository}" ]; then
  echo "--repository is required" >&2
  exit 1
fi

if [ -z "${manifest_path}" ]; then
  echo "--manifest-path is required" >&2
  exit 1
fi

if ! [[ "${max_versions}" =~ ^[0-9]+$ ]] || [ "${max_versions}" -lt 1 ]; then
  echo "--max-versions must be a positive integer" >&2
  exit 1
fi

if [ -z "${github_token}" ]; then
  echo "GitHub token missing. Provide --github-token or set GITHUB_TOKEN." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but was not found in PATH." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

page=1
per_page=100
page_files=()

while :; do
  page_file="${tmp_dir}/page-${page}.json"
  curl -fsSL \
    -H "Authorization: Bearer ${github_token}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${repository}/releases?per_page=${per_page}&page=${page}" \
    > "${page_file}" || printf '[]' > "${page_file}"

  page_count="$(jq 'length' "${page_file}")"
  page_files+=("${page_file}")

  if [ "${page_count}" -lt "${per_page}" ]; then
    break
  fi

  page=$((page + 1))
done

jq -s 'add' "${page_files[@]}" > "${tmp_dir}/all-releases.json"

jq -r '.[] | select(.draft == false and .prerelease == false) | .tag_name' "${tmp_dir}/all-releases.json" \
  | awk '/^[0-9]+\.[0-9]+\.[0-9]+$/' \
  | awk '!seen[$0]++' \
  | awk -F. '{ printf "%09d.%09d.%09d %s\n", $1, $2, $3, $0 }' \
  | sort -r \
  | awk '{ print $2 }' \
  > "${tmp_dir}/sorted-versions.txt"

top_versions_file="${tmp_dir}/top-versions.txt"
head -n "${max_versions}" "${tmp_dir}/sorted-versions.txt" > "${top_versions_file}"

stable_version="$(head -n 1 "${tmp_dir}/sorted-versions.txt" || true)"
if [ -n "${stable_version}" ]; then
  stable_label="stable (${stable_version})"
else
  stable_version=""
  stable_label="stable (latest release)"
fi

all_versions_json="$(
  jq -R . < "${tmp_dir}/sorted-versions.txt" | jq -cs 'map(select(length > 0))'
)"

top_versions_json="$(
  jq -R . < "${top_versions_file}" | jq -cs 'map(select(length > 0))'
)"

entries_json="$(
  jq -cn \
    --arg stable_label "${stable_label}" \
    --argjson top_versions "${top_versions_json}" \
    '
    [
      { key: "stable", label: $stable_label, channel: "stable" },
      { key: "main", label: "main", channel: "main" }
    ] + ($top_versions | map({ key: ., label: ., channel: . }))
    '
)"

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$(dirname "${manifest_path}")"
jq -n \
  --arg stable "${stable_version}" \
  --arg generated_at "${generated_at}" \
  --argjson max_versions "${max_versions}" \
  --argjson versions "${top_versions_json}" \
  --argjson entries "${entries_json}" \
  '
  {
    stable: (if $stable == "" then null else $stable end),
    generated_at: $generated_at,
    max_versions: $max_versions,
    versions: $versions,
    entries: $entries
  }
  ' > "${manifest_path}"

top_versions_csv=""
all_versions_csv=""
if [ -s "${top_versions_file}" ]; then
  top_versions_csv="$(paste -sd, "${top_versions_file}")"
fi
if [ -s "${tmp_dir}/sorted-versions.txt" ]; then
  all_versions_csv="$(paste -sd, "${tmp_dir}/sorted-versions.txt")"
fi

backfill_versions_json="${all_versions_json}"
has_versions="false"
if [ -n "${stable_version}" ]; then
  has_versions="true"
fi

if [ -n "${github_output}" ]; then
  {
    echo "stable_version=${stable_version}"
    echo "stable_label=${stable_label}"
    echo "versions_csv=${top_versions_csv}"
    echo "all_versions_csv=${all_versions_csv}"
    echo "all_versions_json=${all_versions_json}"
    echo "backfill_versions_json=${backfill_versions_json}"
    echo "has_versions=${has_versions}"
  } >> "${github_output}"
fi

echo "stable_version=${stable_version}"
echo "stable_label=${stable_label}"
echo "versions_csv=${top_versions_csv}"
