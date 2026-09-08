#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
target_dir="$HOME/.config/omarchy/plugins/arkane.fat-cat"
omarchy plugin validate "$source_dir"
if [[ "$source_dir" == "$target_dir" ]]; then
  echo "Already in the installed plugin directory."
  exit 0
fi
if [[ -d "$target_dir/.git" ]]; then
  echo "This is a git-managed install; use omarchy plugin update arkane.fat-cat." >&2
  exit 1
fi
mkdir -p -- "$HOME/.config/omarchy/plugins"
staging_dir=$(mktemp -d "$HOME/.config/omarchy/.fat-cat-stage.XXXXXXXX")
backup_dir=""
cleanup() {
  if [[ -d "$staging_dir" ]]; then rm -rf -- "$staging_dir"; fi
  if [[ ! -e "$target_dir" && -n "$backup_dir" && -d "$backup_dir/plugin" ]]; then
    mv -- "$backup_dir/plugin" "$target_dir"
  fi
}
trap cleanup EXIT
mkdir -p -- "$staging_dir/assets"
cp -- "$source_dir"/assets/cat-*.png "$source_dir/assets/GENERATION.md" "$staging_dir/assets/"
for filename in SessionModel.js TimerEngine.qml CatModel.js CatSprite.qml CatPlayground.qml CollectionPanel.qml BreakScene.qml Widget.qml Service.qml manifest.json README.md RELEASE.md LICENSE; do
  cp -- "$source_dir/$filename" "$staging_dir/$filename"
done
omarchy plugin validate "$staging_dir"
if [[ -e "$target_dir" ]]; then
  backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/fat-cat-backup.XXXXXXXX")
  mv -- "$target_dir" "$backup_dir/plugin"
  echo "Previous plugin backed up to $backup_dir/plugin"
fi
mv -- "$staging_dir" "$target_dir"
omarchy-shell shell rescanPlugins
omarchy plugin enable arkane.fat-cat
omarchy restart shell
