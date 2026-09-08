# Marketplace submission

Prepared for the official [publishing guide](https://plugins.omarchy.org/publish.html)
and [submission form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml).
Status: ready for submission; not submitted or approved.

## Form fields

- Title: **[Plugin]: Fat Cat Pomodoro**
- Repository URL: **https://github.com/jeremielumandong/omarchy-fat-cat**
- Category: **Productivity**
- Tags: **Bar**, **Quickshell**
- Suggest a missing tag: leave empty.

## Maintainer notes

Fat Cat Pomodoro is a native Omarchy bar widget and persistent timer service.
Breaks display animated cats with distinct personalities, six activities, a
countdown, and a collection unlocked by completed breaks. It supports adjustable
intervals, pause/resume, safe previews, monitor selection, and reduced motion.

Requires Omarchy's Quattro plugin API and Quickshell 0.3.1 or a compatible newer
runtime, using the installed QtQuick, Quickshell.Io, Quickshell.Wayland, and
Omarchy Ui/Commons modules. There are no build steps or installation hooks.
The only runtime subprocess is coreutils mkdir for the local state directory.
No network services, telemetry, camera, microphone, or root access are used.

Install directly using the README command. Disable and remove using Omarchy's
native plugin commands. Settings are stored in Omarchy's shell configuration;
timer progress is saved locally and retained on removal, as documented.
Blocking breaks can be dismissed with Escape or Skip break.

Code and included generated sprites are MIT licensed. Sprite generation prompts
and provenance are documented in assets/GENERATION.md. preview.png is the
maintainer-provided screenshot used by the README.

Validation: 23 automated tests and native manifest validation passed. Native
Wayland settings/service/layout tests and cross-process persistence tests also
passed during release preparation. See VALIDATION.md for test scope and limits.
The public repository has passing GitHub Actions validation.

## Submission checklist

Review and confirm these in the official form when submitting:

- The repository is public and contains installation and removal instructions.
- The plugin license and external dependencies are documented.
- You own or have permission to submit the plugin and its preview assets.
- The plugin does not overwrite user configuration without explicit consent.
- Approval is for listing and is not a security review.
