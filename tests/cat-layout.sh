#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /tmp/fat-cat-layout.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
for source in CatPlayground.qml CatSprite.qml CatModel.js assets; do
    ln -s "$plugin_dir/$source" "$test_dir/$source"
done
cp "$plugin_dir/tests/cat-layout.qml" "$test_dir/shell.qml"
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME=generic timeout 15 quickshell -p "$test_dir" --no-color 2>&1 | tee "$test_dir/output.log"
grep -q 'PASS: Cats spread' "$test_dir/output.log"
if grep -E 'ERROR|TypeError|ReferenceError|Cannot assign|Cannot open:|Error:' "$test_dir/output.log"; then
    exit 1
fi
