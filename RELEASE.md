# Release 2.0.0

Prepared against the official [development guide](https://plugins.omarchy.org/develop.html)
and [publishing guide](https://plugins.omarchy.org/publish.html).

## Package contract

- Stable non-reserved ID: `arkane.fat-cat`.
- Root `manifest.json`, README, license, original generated assets.
- Native service plus bar-widget; nested settings are not a separate plugin kind.
- No symlinks in the distribution and no packaged Omarchy source edits.
- No network services, root privileges, downloaded dependencies, or install hooks.
- Local install helper is optional; standard `omarchy plugin add` loads the repo directly.

## Validation

Run `bash scripts/check.sh`, `omarchy plugin validate "$PWD"`, and QML checks
against installed Omarchy and Quickshell imports. `qs.*` is a virtual runtime
namespace, so standalone qmllint may require a temporary `qs` import mapping
outside this repository; do not ship symlinks as part of the plugin.

On an Omarchy Wayland session verify:

1. Bar click and IPC `shell summon arkane.fat-cat '{}'` open settings; Escape
   and `shell hide arkane.fat-cat` close it. Reopening works.
2. Preview leaves phase/deadline/counters unchanged and closes automatically.
3. Timer pause/resume, long breaks, skipping and collection thresholds work.
4. Save/restart restores paused and running sessions; no persistence warnings.
5. Tab through all settings and cat name/favorite controls at small scale.
6. Blocking and gentle overlays, monitor unplug fallback, reduced motion.
7. Disable, re-enable, shell restart and removal work without other changes.
8. `omarchy-shell fat-cat status` reports `2.0.0` from the running shell.

## Verification commands

```sh
bash scripts/check.sh
bash tests/persistence-smoke.sh
bash tests/ui-smoke.sh
bash tests/service-smoke.sh
bash tests/cat-layout.sh
bash tests/render-preview.sh
```

Runtime tests use isolated temporary session files and never alter your real
collection. Wayland tests briefly open their own windows and exit automatically.
The render command replaces the repository preview.png with a fresh screenshot
of the plugin alone.

## Publish

The public repository is https://github.com/jeremielumandong/omarchy-fat-cat.
README, MIT license, generated-asset provenance, preview, and CI are included.
The public HTTPS clone passed the native manifest validator. The plugin ID stays
stable so existing installations retain their configuration.

Submit using the official [issue form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml).
[MARKETPLACE.md](MARKETPLACE.md) contains the prepared fields and maintainer notes.
Use category **Productivity** and the supported tags **Bar**, **Quickshell**.
The form accepts one to three predefined tags; custom tags need a separate suggestion.

Marketplace submission has not been sent. Automated validation checks the
submitted repository commit before a maintainer approves the listing. Local
validation and GitHub CI do not constitute marketplace approval.
