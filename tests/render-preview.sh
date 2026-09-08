#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
shell_dir=${OMARCHY_SHELL_DIR:-/usr/share/omarchy/shell}
test_dir=$(mktemp -d /tmp/fat-cat-render.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
for module in Commons Ui; do ln -s "$shell_dir/$module" "$test_dir/$module"; done
for source in "$plugin_dir"/*.qml "$plugin_dir"/*.js "$plugin_dir/assets"; do ln -s "$source" "$test_dir/$(basename -- "$source")"; done
cp "$plugin_dir/tests/render-preview.qml" "$test_dir/shell.qml"
FAT_CAT_PREVIEW_PATH="$plugin_dir/preview.png" timeout 15 quickshell -p "$test_dir" --no-color
