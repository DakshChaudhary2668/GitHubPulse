<div align="center">

<img src="docs/github-pulse-icon.png" width="180" height="180" alt="GitHub Pulse app icon">

# GitHub Pulse

### Your code. Your consistency. Your desktop.

**A beautiful, lightweight GitHub contribution widget for macOS.**

Built natively with SwiftUI and WidgetKit. No Electron. No tracking. Just your progress.

[![macOS](https://img.shields.io/badge/macOS-14%2B-111111?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white)](https://www.swift.org/)
[![License](https://img.shields.io/badge/License-MIT-222222?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Development_Preview-238636?style=flat-square)](RELEASE_CHECKLIST.md)

<br>

![GitHub Pulse on macOS](docs/connection.png)

<sub>Native macOS desktop widget · Actual GitHub activity · Minimal by design</sub>

<br>

**[Get Started](#get-started) · [Explore Features](#features) · [Architecture](#under-the-hood) · [Contribute](CONTRIBUTING.md)**

</div>

---

## A little progress, every day.

Your GitHub contribution graph shouldn't live behind another browser tab.

**GitHub Pulse brings your development activity directly to your desktop**, turning your contribution history into a quiet reminder of the work you're putting in.

No clutter. No distractions. Just a native widget that feels like it belongs on your Mac.

## Features

| | |
|---|---|
| **Contribution Heatmap** | 14 weeks of daily GitHub activity in a compact, GitHub-green grid |
| **Your GitHub Identity** | Actual profile avatar and configurable username |
| **Contribution Insights** | Annual contribution total and current streak |
| **Native macOS Widgets** | Small, Medium and Large layouts, each with a contribution heatmap |
| **Transparent Desktop Panel** | An optional movable panel with a clear or frosted background |
| **Smart Refresh** | System-managed updates with manual refresh |
| **Local Talkback** | Speak annual contributions, day streak and saved sync time using macOS speech, without another API key |
| **Offline Ready** | Cached contributions remain visible without internet |
| **Secure by Design** | Credentials stored in macOS Keychain |
| **Lightweight** | No Electron, webviews, third-party runtime dependencies or analytics |

---

## Get Started

<sub>Requires macOS 14+, Xcode 26+ with the macOS 26 SDK (for the availability-guarded glass API), and a configured Apple development team.</sub>

**01 — Clone**

```bash
git clone https://github.com/DakshChaudhary2668/GitHubPulse.git
cd GitHubPulse
```

**02 — Configure**

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

Set your development team and unique bundle identifier in `Config/Local.xcconfig`.

**03 — Build**

Open `GitHubPulse.xcodeproj` in Xcode, select the **GitHubPulse** scheme and run on **My Mac**.

Both targets must use the same development team and compatible App Group/Keychain entitlements.

**04 — Connect**

Enter your GitHub username and an expiring personal access token in the settings app, then select **Save & Refresh**.

For a classic token, use `read:user` where required. Avoid granting broad repository permissions.

**05 — Add to Desktop**

Control-click your desktop → **Edit Widgets** → **GitHub Pulse** → choose Small, Medium or Large.

That's it. Your GitHub activity, always in sight.

---

## Designed to feel native.

| Native first | Privacy first | Battery conscious |
|:---:|:---:|:---:|
| **SwiftUI + WidgetKit** | **macOS Keychain** | **System-managed refresh** |
| No browser wrappers | No analytics or telemetry | No aggressive polling |

**Glass host preview** uses native glass on macOS 26 and later, with a material fallback on earlier supported versions. Reduce Transparency and increased contrast use an opaque surface. WidgetKit manages the native widget’s tint, and Full Color preserves the green heatmap.

It requests refresh opportunities approximately every 30 minutes, but macOS ultimately controls the update schedule. Manual refresh is available in the host app.

### Offline behavior

After a successful sync, GitHub Pulse keeps the last saved contributions and
profile photo locally. If the Mac is offline, a failed refresh retains that
snapshot instead of clearing it. The displayed sync time refers to the saved
data; activity may therefore be out of date. Before the first successful sync,
there is no activity to display and the app shows the connection/setup state.

Theme switching and speaking saved contributions do not require internet.
Appearance reloads briefly reuse saved activity instead of waiting for GitHub;
normal data refresh resumes afterward. WidgetKit still controls render timing,
so appearance changes are not guaranteed to be instantaneous.
The heatmap computes its 14-week grid once per redraw. The desktop panel skips
redraws for unchanged cached activity, and the app checks Keychain status off
the main thread.

Reconnecting to the internet does not guarantee an immediate refresh. New data
arrives at the next system-scheduled opportunity, or when you open the app and
choose **Save & refresh**. The normal requested refresh interval is 30 minutes;
macOS may run it later. Disconnect intentionally removes the saved account data.

### Appearance

Choose an appearance in the app, or use the theme button on the card to cycle
**System → Light → Dark → Transparent → System**. Light uses dark text on white.
Dark uses light text on black. System follows macOS.

**Desktop panel.** Select **Transparent** while the app is running, or turn on
**Show desktop panel**. The panel stays open as you change themes. In Transparent
mode, **Frosted panel background** adds wallpaper blur. Uncheck it for a clear
background while keeping the card visible. The clear panel uses a subtle shadow
for contrast. Light mode keeps the text unshadowed.

Drag the panel to move it, use **Widget preview** to resize it, or right-click and
choose **Hide desktop panel**. The panel stays open when you quit the main app.
Its helper exits when you hide the panel. It watches saved settings and activity
for changes and shows a fixed sync time, so it can idle between updates.
To refresh while the main app is closed, open Notification Center, choose
**Edit Widgets**, and add the native **GitHub Pulse** widget to Notification
Center. It shares its updates with the panel without adding a second desktop
card. macOS schedules those refreshes. Use **Save & refresh** in the app for
an immediate request. Double-click the panel or click the native widget to
open GitHub Pulse.

**Native widget.** Transparent uses a faint tint, soft highlights and a reflective
edge within the surface provided by WidgetKit. macOS controls the final tint.
On macOS 15 and later, tinted profile photos retain their detail in monochrome.

### Widget sizes and local speech

Small and Large use macOS's square footprints; Medium is a wide rectangle. All
three show the 14-week heatmap, profile, annual contribution total and streak.
The host preview selector also resizes the app-managed desktop panel. Use the
native widget’s context menu to change its size.

Click **Speak contributions** below the host preview, or **Stop speaking** to
interrupt playback. All three sizes have a speaker button that runs a background audio action
without requesting a settings window. Open the app from its Dock icon for settings. Speech is explicit: no audio during refresh
or merely showing a widget. It reads the current saved snapshot, for example:
“190 GitHub contributions. 1-day streak. Synced at 12:45 PM.” Older syncs include
the date. Widget speech reads the saved snapshot locally; no token, count or text is
passed through the widget action.

Medium uses equal 14-point padding on all sides, a 14-by-7 grid of 9-point
square cells, and statistics aligned toward the right. Its enlarged profile photo
sits on the right, with the speaker aligned to the username row above it.
Small uses a full-width bold username and centered heatmap. Large places the
photo beside the username, centers the heatmap between two statistic rows,
and shows annual contributions, streak, contributions in 14 weeks, and active
days. Active days count dates with contributions in the displayed 14-week range.
Widget speaker buttons run background audio without requesting a settings
window. The New Window command is removed; open settings through the Dock.

---

## Under the Hood

```text
                   GITHUB
               GraphQL + REST
                     |
                     v
              GitHub API Client
                     |
                     v
             Shared App Group
              Cached Snapshot
                     |
              +------+------+
              |             |
              v             v
         macOS Host      WidgetKit
          Settings       Extension
```

**SwiftUI** renders the interface. **WidgetKit** manages widget timelines. **URLSession** fetches GitHub data. **Keychain** securely stores credentials, while the **App Group** shares cached contribution data between processes.

The heatmap displays 14 Sunday-aligned weeks, while the headline count reflects GitHub's annual contribution total. Streaks allow an unfinished current day and are limited to the returned history.

Cross-process locking and account revision checks prevent outdated refreshes from restoring disconnected account data.

<details>
<summary><strong>Project structure</strong></summary>

| File | Purpose |
|---|---|
| `Sources/Core.swift` | Models, API client, contribution calculations |
| `Sources/Storage.swift` | Keychain, shared cache, account revisions |
| `Sources/Card.swift` | Widget UI |
| `Sources/App.swift` | Settings and authentication |
| `Widget/Widget.swift` | WidgetKit timeline provider |
| `Config/` | Signing configuration |
| `Tests/` | Regression tests |
| `scripts/` | Build and security checks |

</details>

<details>
<summary><strong>Security and data handling</strong></summary>

Tokens are stored in the shared macOS data-protection Keychain and sent to GitHub's GraphQL API through HTTPS Authorization headers. They are never written into the JSON cache.

The cached snapshot contains profile activity and avatar data, protected by the app sandbox but not independently encrypted.

Disconnect removes the local token and cached snapshot and requests widget reloads. It does not revoke the token on GitHub, and macOS may temporarily retain previously rendered snapshots.

No telemetry or analytics are collected. See [SECURITY.md](SECURITY.md).

</details>

<details>
<summary><strong>Build and verification</strong></summary>

```bash
scripts/test.sh
python3 scripts/audit.py

xcodebuild \
  -project GitHubPulse.xcodeproj \
  -scheme GitHubPulse \
  -configuration Release \
  -derivedDataPath /tmp/PulseBuild \
  CODE_SIGNING_ALLOWED=NO build
```

Tests are standalone Swift regression executables, not XCTest. Unsigned builds cannot verify signed Keychain/App Group behavior or installed desktop rendering.

</details>

<details>
<summary><strong>Troubleshooting</strong></summary>

- **Blank widget after replacing a development build:** A still-running old extension can cause a bundle-version mismatch. Quit the old GitHub Pulse widget process before replacing the app, then open the installed host and use Save & Refresh. Do not delete account containers or Keychain entries.
- **Generic gallery icon:** Verify the installed signed app contains its icon assets. In one local session a Mac restart resolved a stale gallery icon after registration repairs; this is not a guaranteed fix.
- **Widget missing:** Run the signed host from a stable Applications location and reopen Edit Widgets.
- **Desktop widgets disabled:** Enable them in System Settings → Desktop & Dock.
- **Appearance tinted:** Choose Full Color widget style.
- **Signing issues:** Check both targets' development team and resolved entitlements.
- **Development build won’t open after a week:** Apple Personal Team profiles
  expire after seven days. Rebuild and reinstall the signed app and embedded
  widget with renewed profiles. The maintainer’s local renewal job checks profile
  expiry offline and uses Xcode online when renewal is due. Its schedule, signing
  settings and private source copy live outside the published project.
  [Apple’s Personal Team limits](https://developer.apple.com/help/account/basics/about-your-developer-account)
- **Authentication errors:** Check token expiration, permissions, organization policies and rate limits.
- **Xcode components missing:** Complete Xcode first-launch setup using Apple's supported tooling.

</details>

---

## Project Status

> **Development Preview — Source Only**
>
> GitHub Pulse is not yet a stable v1.0.0 release. Live account-switching and installed test-widget verification remain incomplete. No signed or notarized binary is distributed.

| Milestone | Status |
|---|---|
| Native macOS application and widgets | Complete |
| GitHub contribution calendar and profile | Complete |
| Keychain and App Group integration | Locally verified |
| Offline caching and account management | Locally tested |
| Live account-switching verification | Pending |
| Installed test-widget verification | Pending |
| Hosted CI validation | Pending |
| v1.0.0 stable release | On hold |

See [Security Audit](AUDIT.md), [Release Checklist](RELEASE_CHECKLIST.md), and [Changelog](CHANGELOG.md).

---

## Contributing

GitHub Pulse is open source, and contributions are welcome.

Found a bug? Have an idea? Want to improve the macOS experience?

Read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request. For vulnerabilities, follow the [Security Policy](SECURITY.md).

## License

Distributed under the [MIT License](LICENSE).

---

<div align="center">

**Built for developers who trust the process.**

Made with SwiftUI, WidgetKit, and a little obsession with clean interfaces.

[GitHub](https://github.com/DakshChaudhary2668/GitPulse) · [Contribute](CONTRIBUTING.md) · [Report an Issue](https://github.com/DakshChaudhary2668/GitPulse/issues)

<sub>Independent project. Not affiliated with GitHub or Apple.</sub>

</div>
