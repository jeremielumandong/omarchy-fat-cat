#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d /tmp/fat-cat-persistence.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
cp "$plugin_dir/TimerEngine.qml" "$plugin_dir/SessionModel.js" "$test_dir/"
cp "$plugin_dir/tests/persistence-smoke.qml" "$test_dir/shell.qml"
for stage in write read; do
  FAT_CAT_TEST_STAGE="$stage" QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic timeout 15 quickshell -p "$test_dir" --no-color > "$test_dir/$stage.log" 2>&1
  cat "$test_dir/$stage.log"
  if rg 'ERROR|TypeError|ReferenceError|Cannot assign' "$test_dir/$stage.log"; then exit 1; fi
  rg -q 'PASS: atomic snapshot writes completed' "$test_dir/$stage.log"
done
rg -q 'PASS: paused session and settings restored' "$test_dir/read.log"
