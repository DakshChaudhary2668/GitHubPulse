# GitHub Pulse

<img src="docs/app-icon.png" width="128" height="128" alt="GitHub Pulse app icon: green contribution cells forming a pulse on charcoal">

> **Development-stage source:** This project is not a v1.0.0 release. Live account-switching and installed test-widget verification remain incomplete. No signed/notarized binary is distributed.

A lightweight native macOS contribution widget built with SwiftUI and WidgetKit.

GitHub Pulse puts your contribution calendar, profile avatar, annual contribution total and current streak on your desktop. A small settings app handles authentication and manual refresh. No third-party runtime dependencies, webviews or analytics.

![GitHub Pulse reference supplied by the maintainer](docs/connection.png)

Maintainer-supplied visual reference, published with permission. It shows the maintainer’s public GitHub username and avatar. Its contribution figures reflect an earlier 14-week display; current source labels the annual total separately. This image is a design reference, not verification of the remaining release gates.

## Features

- Medium and large desktop widgets with a charcoal background and GitHub-green heatmap
- Fourteen Sunday-aligned weeks of daily contributions, with the annual total labeled separately
- Actual GitHub avatar and configurable username
- A streak that allows today to remain incomplete
- Cached activity when offline, with freshness indication
- Shared macOS data-protection Keychain credentials
- Manual refresh and confirmed local disconnect

## Requirements and installation

macOS 14 or later; Xcode with Swift 6 support (Xcode 16 or later). Development has been tested with Xcode 27.2 / Swift 6.4.2. This is a source-release candidate; no downloadable signed/notarized application is provided yet.

1. Download the approved source or clone `DakshChaudhary2668/GitPulse` once published.
2. Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig`.
3. Set your development team and a unique reverse-DNS bundle identifier in the local file. Keep the same configuration for both targets.
4. Open `GitHubPulse.xcodeproj`, select the GitHubPulse scheme, and build/run on My Mac.
5. Configure GitHub in the host app. Control-click the desktop → Edit Widgets → GitHub Pulse. Add Medium or Large. WidgetKit provides preset sizes, not arbitrary resizing.

`Config/Local.xcconfig` is ignored and must never be committed. Do not remove sandbox, Keychain or App Group entitlements to bypass signing failures.

## Reproducible signing configuration

`Config/Release.xcconfig` supplies portable defaults and optionally includes the local file. `PULSE_BUNDLE_ID` determines the host ID and the extension's `.Widget` ID. `PULSE_GROUP_SUFFIX` determines the team-prefixed macOS App Group. `PULSE_KEYCHAIN_SUFFIX` determines the shared Keychain group, prefixed by Apple's AppIdentifierPrefix. Both Info plists and entitlement files derive their values from these settings.

Use the same Apple team for both targets. The team-prefixed macOS App Group is supported without registering a `group.` identifier. Keychain sharing still requires a valid signing identity/profile. Personal Team profiles may expire quickly; inspect the actual profile expiration and rebuild as necessary. Changing identifiers creates separate storage and may require reconnecting.

Existing users should retain their previous local configuration. The first updated run recovers the username from the existing shared snapshot and uses the same Keychain account name. The release-preparation process does not modify your installed widget or its data.

## Authentication and disconnect

Enter a GitHub username and personal access token in the host app, then Save & refresh. Create tokens only on [GitHub's token settings page](https://github.com/settings/tokens), with an expiration. For a classic token, `read:user` permits private/internal contribution information where GitHub allows it. Do not grant broad `repo` access just to populate this calendar. Fine-grained token support depends on the queried resources and organization policies; it has not been verified here.

The app sends tokens only in the Authorization header to `api.github.com/graphql`. Tokens are stored in the shared data-protection Keychain, never in JSON caches. Public profile metadata and avatars are fetched over HTTPS. Do not paste credentials into issues, logs, chat, source files or CI variables.

Disconnect GitHub removes the local saved token and shared snapshot and requests widget reloads. An in-flight network request may finish, but its outdated account revision cannot commit a new cache. macOS may temporarily retain an already-rendered widget snapshot. Disconnect does not revoke a GitHub token; revoke it separately on GitHub if it is no longer needed. Account changes remove the previous account's saved token.

## Data and refresh behavior

The headline uses GitHub's calendar `totalContributions` for the returned annual collection. The graph displays fourteen weeks, so it is not expected to sum to that annual headline. GitHub returns date-only keys; calculations consistently use UTC. Private visibility, organization authorization and GitHub processing delays can produce differences from a signed-in website. Streaks are bounded by the returned annual history.

The widget requests refresh opportunities approximately every 30 minutes. WidgetKit budgets and schedules updates; timing is not guaranteed. The app does not run an aggressive background polling loop. Manual refresh requests a timeline reload. Failed refreshes preserve cached activity. Data older than one hour or following a widget fetch failure is marked cached.

## Architecture

`Sources/Core.swift` contains Codable models, date/streak calculations, username validation and the URLSession API client. `Sources/Storage.swift` manages the shared JSON snapshot, account revision and Keychain. A file lock serializes cross-process account changes/cache commits. `Sources/Card.swift` is the shared approved widget design. `Sources/App.swift` provides settings. `Widget/Widget.swift` provides timelines and medium/large configurations.

The cache includes profile activity and an avatar; it is protected by the sandbox but is not independently encrypted. No credentials enter it. No telemetry is collected.

## Build and test

```sh
scripts/test.sh
python3 scripts/audit.py
xcodebuild -project GitHubPulse.xcodeproj -scheme GitHubPulse \
  -configuration Release -derivedDataPath /tmp/PulseBuild \
  CODE_SIGNING_ALLOWED=NO build
```

Unsigned builds check compilation and extension embedding; they cannot validate signed Keychain/App Group access. CI runs these checks on macOS without signing credentials. Tests are standalone Swift regression executables, not an XCTest target.

## Troubleshooting

- Missing from the gallery: run the signed host from a stable Applications location, then reopen Edit Widgets. A registered extension alone does not prove gallery rendering works.
- Widgets hidden on desktop: System Settings → Desktop & Dock → Widgets → enable On Desktop.
- White/tinted appearance: use Full Color widget style; this app marks its charcoal container background nonremovable. Remove/re-add an old widget after an update if its snapshot is stale.
- Keychain/App Group error: verify both targets' team, resolved entitlement prefixes and local configuration. Never disable security entitlements as a workaround.
- Authentication failure: check expiration, `read:user`, organization policies and API rate limits. Save a replacement token securely in the app.
- Xcode missing components: open Xcode and complete first-launch installation using Apple's tooling. Do not copy frameworks manually.

## Status and contributing

See [AUDIT.md](AUDIT.md), [release checklist](RELEASE_CHECKLIST.md), [changelog](CHANGELOG.md), [contribution guide](CONTRIBUTING.md) and [security policy](SECURITY.md). Runtime account switching and disconnect require signed integration verification before v1.0.0. GitHub Pulse is independent of GitHub and Apple.

References: [GitHub contribution schema](https://docs.github.com/en/graphql/reference/users), [GitHub authentication](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql), [Apple App Groups](https://developer.apple.com/documentation/xcode/accessing-app-group-containers), [WidgetKit refresh scheduling](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

Licensed under MIT.

## First hosted CI validation plan

After separate approval to publish source, push only the reviewed manifest. Keep Local.xcconfig, build products, caches and review files excluded. Enable Actions and invoke **macOS checks** manually (workflow_dispatch) or inspect its first push run. No signing certificates or GitHub API credentials should be configured.

Verify the runner reports a Swift 6-capable Xcode, the publication audit succeeds, both regression executables pass, the unsigned Release host/extension builds, and the embedded extension check passes. Review logs for accidental sensitive output. A passing run validates source compilation/tests, not signed sandbox behavior or desktop installation. If a runner/toolchain differs from local validation, record it and fix the workflow before tagging. Never upload an unsigned CI app as a signed installer. Record the run URL and commit SHA in the release checklist after the actual run.

## App icon

The original app mark turns contribution cells into a pulse, using the widget’s charcoal and green palette. No GitHub trademark artwork or third-party imagery is embedded. Regenerate the macOS icon and documentation preview with `swift scripts/make-icon.swift` on macOS.
