#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
for test_file in tests/*.test.cjs; do
  node "$test_file"
done
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin validate "$PWD"
fi
