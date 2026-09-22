#!/usr/bin/env bash
# Build the Astro documentation site from package.json5 without persisting a generated package.json.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docs_dir="$(cd "${script_dir}/.." && pwd)"

cd "${docs_dir}"
trap 'rm -f package.json' EXIT
sed -E 's@[[:space:]]*//.*$@@' package.json5 > package.json
pnpm install --frozen-lockfile
pnpm exec astro build

echo "Static site built: ${docs_dir}/dist"
