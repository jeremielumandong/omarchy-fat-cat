#!/usr/bin/env bash
set -euo pipefail
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
shell_dir=${OMARCHY_SHELL_DIR:-/usr/share/omarchy/shell}
test_dir=$(mktemp -d /tmp/fat-cat-service-smoke.XXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
for module in Commons Ui; do
    ln -s "$shell_dir/$module" "$test_dir/$module"
done
for source in "$plugin_dir"/*.qml "$plugin_dir"/*.js "$plugin_dir/assets"; do
    ln -s "$source" "$test_dir/$(basename -- "$source")"
done
cp "$plugin_dir/tests/service-smoke.qml" "$test_dir/shell.qml"
for stage in focus paused break; do
    node - "$plugin_dir" "$test_dir" "$stage" <<'NODE'
const fs = require('node:fs');
const [plugin, dir, stage] = process.argv.slice(2);
const M = require(plugin + '/SessionModel.js');
let s = M.configure(M.initial(), 42, 7, 21, 4);
s.completedFocus = 2; s.completedBreaks = 1;
s = M.start(s, Date.now());
if (stage === 'paused') s = M.pause(s, Date.now());
if (stage === 'break') s = M.tick(s, s.deadline);
fs.writeFileSync(dir + '/state.json', JSON.stringify(s) + '\n');
NODE
    FAT_CAT_TEST_STAGE="$stage" timeout 15 quickshell -p "$test_dir" --no-color > "$test_dir/$stage.log" 2>&1
    cat "$test_dir/$stage.log"
    if rg 'ERROR|TypeError|ReferenceError|Cannot assign|Error:' "$test_dir/$stage.log"; then exit 1; fi
    rg -q 'PASS: safe preview' "$test_dir/$stage.log"
done
