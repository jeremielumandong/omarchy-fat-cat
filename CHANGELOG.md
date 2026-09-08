# Changelog

## 2.0.0

- Persistent atomic session storage and startup recovery.
- Pause/resume and configurable long-break cycles.
- Independent 15-second preview with no timer/progress side effects.
- Four cat personalities; six generated animation states for each cat.
- Gradual collection unlocks, names, and favorites without streak penalties.
- Native Timer/Cats settings tabs with scrolling and keyboard access.
- Reduced motion, gentle/blocking break selection, and monitor preference/fallback.
- Clean local installation helper, MIT license, CI, and release documentation.
- Model, asset, Wayland integration and process-restart tests.

v1 prototypes kept timer state only in memory. Their active timer resets once on
upgrade; existing saved interval settings are retained. v2 sessions restore after
subsequent restarts.
