# Proposed v1.0.0 checklist

- [x] Prepare source, configuration templates, MIT license and project documentation.
- [x] Validate unsigned Release host build and embedded extension locally.
- [x] Run core regression checks and publication-pattern audit.
- [ ] Review final publication manifest and screenshot manually.
- [ ] Verify signed account migration with the existing identifiers, using a backup/disposable environment.
- [ ] Verify account switching, Keychain errors, disconnect, stale concurrent refresh, cache removal and offline behavior with disposable credentials.
- [ ] Verify both widget sizes, desktop appearance, accessibility and profile links on supported macOS versions.
- [ ] Run GitHub Actions on the approved repository; no CI run is claimed before publication.
- [ ] Enable private vulnerability reporting and repository secret scanning where available.
- [ ] Confirm license ownership, documentation and any screenshot permissions.
- [ ] Approve the security audit and exact publishable file set.
- [ ] Only after separate explicit authorization: initialize/import Git, re-audit all history, push, tag v1.0.0 and publish release notes.

No publishing action is authorized by this checklist. A signed/notarized binary release needs separate signing, notarization and verification work; do not distribute the unsigned CI build as an installable release.

Final gate status: HOLD. See the dated gate table in AUDIT.md. Signed isolated storage switching/disconnect passed; live GitHub switching and confirmation/widget UI remain unverified by user choice. Hosted Actions and publication approval are still pending. The repository target supplied for this gate is DakshChaudhary2668/GitPulse.

### Follow-up evidence

- [x] Read-only cache investigation: mtime matches production widget successful reload at 04:40:18 IST; legitimate-refresh explanation supported, exclusive attribution not proven.
- [x] Negative production App Group/Keychain access checks denied under test entitlements.
- [x] Separately provisioned signed host: confirmation, Cancel, Disconnect and empty UI verified with synthetic data.
- [x] Post-UI Disconnect token/cache deletion independently verified; production app hashes unchanged.
- [x] Reviewed all 26 publication candidates and account-free screenshot.
- [x] Documented first hosted Actions run plan; manual workflow trigger added.
- [ ] Test distinct extension from stable installation: temporary test bundle hit chronod descriptor/FOREIGN KEY errors; no successful render claimed.
- [ ] Verify live switching and widget updates with disposable credentials, hosted CI and remaining integration gates before v1.0.0.

Source-only pre-release publication may be approved separately; no approval to publish, tag or distribute is implied. Signed binary distribution remains blocked on distribution signing/notarization and runtime verification.
