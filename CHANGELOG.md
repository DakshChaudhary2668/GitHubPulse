# Changelog

## 1.0.0 — Proposed, unreleased

- Native SwiftUI settings application and medium/large WidgetKit widgets.
- Real contribution calendar, annual API total, fourteen-week graph and current streak.
- Real avatar, dark appearance and configurable GitHub username.
- Shared Keychain authentication, atomic shared cache and offline freshness state.
- Confirmed local disconnect with account-revision protection against stale cache writes.
- Portable developer configuration, regression tests, unsigned macOS CI and release audit tooling.

Not published or tagged. Signed account-switch/disconnect integration validation remains required.

## Unreleased — adaptive widgets and local speech

- Small, Medium and Large heatmaps with system-aware desktop rendering.
- Host glass preview with accessibility fallbacks and immediate size selection.
- Local speech for contribution count, streak and sync time; speaker links on Medium/Large.
- Medium content padding and compact layout; enlarged app icon and asset catalogs.
- Fresh cached timelines return immediately; network requests have bounded timeouts.
- Document stale extension recovery after local app replacement.

- Enlarged profile photos, centered Small/Large heatmaps and bold identity text.
- Large statistics show annual and 14-week contributions, streak and active days.
- Repeated speaker links reuse the existing window in tested interactions.

## Unreleased — appearance controls

- Shared System, Light and Dark appearance selector and native widget buttons.
- White/light and black/dark surfaces with the existing green heatmap.
- Small speaker link and spaced right-aligned contribution/streak statistics.

## Unreleased — background actions and release hardening

- Widget speech runs as a background audio action without requesting a window.
- Restored glass in Light/Dark and added translucent accessible widget backgrounds.
- Large layout uses native preview dimensions, extra padding and spaced controls.
- Avoid duplicate theme reloads and network waits when changing cached appearance.
- Documented offline behavior and remaining release verification gates.
