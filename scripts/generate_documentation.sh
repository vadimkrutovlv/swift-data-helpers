#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

OUTPUT_PATH="${DOCS_OUTPUT_PATH:-./docs}"
TARGET_NAME="${DOCS_TARGET:-SwiftDataHelpers}"
HOSTING_BASE_PATH="${DOCS_HOSTING_BASE_PATH:-swift-data-helpers}"

mkdir -p "${OUTPUT_PATH}"

swift package --allow-writing-to-directory "${OUTPUT_PATH}" \
  generate-documentation \
  --target "${TARGET_NAME}" \
  --output-path "${OUTPUT_PATH}" \
  --transform-for-static-hosting \
  --hosting-base-path "${HOSTING_BASE_PATH}"
