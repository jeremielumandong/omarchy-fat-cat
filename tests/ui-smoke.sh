#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_dir=${OMARCHY_SHELL_DIR:-/usr/share/omarchy/shell}
test_dir=$(mktemp -d /tmp/fat-cat-ui-smoke.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
for module in Commons Ui; do
    ln -s "$shell_dir/$module" "$test_dir/$module"
done
for source in "$plugin_dir"/*.qml "$plugin_dir"/*.js "$plugin_dir/assets"; do
    ln -s "$source" "$test_dir/$(basename -- "$source")"
done
cp "$plugin_dir/tests/ui-smoke.qml" "$test_dir/shell.qml"
timeout 15 quickshell -p "$test_dir" --no-color 2>&1 | tee "$test_dir/output.log"
grep -q 'PASS: Widget creates' "$test_dir/output.log"
if grep -E 'ERROR|TypeError|ReferenceError|Cannot assign|Cannot open:' "$test_dir/output.log"; then
    exit 1
fi
