# Proposed v1.0.0 release gate

Status: HOLD. Feature freeze: fixes, verification and documentation only.
GitHub Pulse remains publicly available under MIT. Commercial options were
discussed but no pricing, payment, license or visibility changes are authorized.
Repository: https://github.com/DakshChaudhary2668/GitHubPulse

## Established evidence

- [x] Public source repository and MIT license exist.
- [x] Hosted CI passed for appearance commit `09a3372`: audit, regression tests,
  unsigned host/extension build, embedded extension and app icon checks.
- [x] Local signed host/extension builds and strict signature verification passed
  for background audio and restored glass changes; hosted CI must check this candidate.
- [x] Existing core, account-revision, isolated storage and speech-summary tests pass.
- [x] Isolated signed Disconnect confirmation, cancellation and data removal were
  verified with synthetic data; production storage was not used for those tests.
- [x] Background speaker action produced two speech-start events with zero visible
  host windows. Diagnostics contain only a window count, not account information.
- [x] Light/Dark host glass previews and Small/Large desktop content were inspected.
- [x] Previous signed installation's identity, account, Keychain and cache preserved.

## Remaining v1.0.0 blockers

- [x] Final Large padding/control-gap and footer inspected on the native widget.
- [ ] Repeat Small/Medium/Large resizing after the installed candidate has rendered
  every family. Old bundle-version archives caused blank first renders; recovery
  was observed, but no permanent elimination of blanking is claimed.
- [ ] Verify theme and speaker with host running, window closed, and host quit;
  verify Dock opens/reuses the settings window. No blanket cold-start pass claimed.
- [ ] Confirm audible background speech with the user; speech-start diagnostics
  alone do not prove audible output quality.
- [ ] Test Light/Dark/System, system tint, Reduce Transparency and increased contrast
  across widget families, including the macOS 14 fallback on supported hardware.
- [ ] Verify live account switching and widget cache isolation using disposable
  credentials. User previously chose isolated testing; live testing stays unverified.
- [ ] Review the Octocat-derived icon: GitHub's logo policy disallows its marks as
  another product's app icon, including free/open-source products. Replace with
  original artwork with user approval, or establish written permission.
- [ ] Re-audit exact staged files, publication manifest and current history before
  any further approved push; run hosted CI on the final candidate.
- [ ] Obtain explicit approval before a version tag or GitHub Release.

## Optional future binary distribution (not part of source release)

- [ ] Configure Developer ID distribution signing; only an Apple Development
  identity was available during this audit. Do not distribute development/CI builds.
- [ ] Verify hardened runtime, host/extension entitlements, distribution profiles,
  notarization and stapling, and test the downloaded artifact with Gatekeeper.
- [ ] Test clean installation and upgrade on a separate Mac/account without the
  developer's signing setup, App Group data or credentials.

Source preparation is not authorization to publish a tag, release or binary.
Detailed chronological evidence and earlier checkpoints remain in AUDIT.md.

References: [GitHub logo policy](https://brand.github.com/foundations/logo),
[Apple distribution](https://developer.apple.com/macos/distribution),
[MIT license](https://opensource.org/license/mit).
