# Release validation

Validated on the development Omarchy Wayland session on 2026-09-08.

- `bash scripts/check.sh`: 23 passing assertions covering sprite transparency,
  behavior, timer state transitions, persistence validation, and package contract.
- Official `omarchy plugin validate`: passed.
- Native Quickshell persistence test: saved and restored a paused configured timer
  across two processes using an isolated state file.
- Native settings test: rejected invalid intervals, saved settings without resetting
  the session, opened the collection, and exercised preview and panel reopening.
- Native service tests: focus, paused, and break fixtures preserved real session
  state during previews; preferences, locked cats, and monitor fallback passed.
- Native layout test: four cats remained separated and bounded after zero-sized
  creation, 1280×720 layout, and resizing to 400×300 with reduced motion enabled.
- Rendered and visually inspected `preview.png` using the real break scene.

Standalone qmllint reports warnings for dynamic Omarchy theme properties and
runtime-created window types. It is not a clean lint pass; native test execution
was used to check these bindings. Runtime logs also contain a host portal app-ID
registration warning in the temporary test process.

Marketplace approval, installation from a public GitHub URL, and testing on other
Omarchy versions remain release follow-up checks. See RELEASE.md for commands
and the broader manual compatibility checklist.
