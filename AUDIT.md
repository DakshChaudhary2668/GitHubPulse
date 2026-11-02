# Release security audit — 2026-11-03

## Scope and findings

The entire project directory, including hidden files, was inventoried. No `.git` repository exists locally; consequently there is no local Git history to inspect, and no remote repository/history was fetched. An all-history audit is required if any existing history is imported. No repository was created, pushed or published.

No GitHub token or private signing key was found in publishable files by the automated patterns and source review. This is a bounded review, not proof against every possible credential format. Credentials in the system Keychain were not extracted or printed.

Found and excluded from publication:
- A local Apple team identifier, now in ignored `Config/Local.xcconfig`.
- Personal Xcode user-state directories, ignored.
- Real-account design screenshots, ignored under `Design/`.
- Historical development notes with personal paths and signing diagnostics, retained only under ignored `.release-local/`.

The public connection screenshot is rendered directly from the real SwiftUI view with no account data. Public documentation contains the intended repository owner/name but no private contact address or machine path. Signing certificates, profiles, app bundles and runtime caches are excluded. Do not upload the whole working directory as an archive; publish only the reviewed manifest below.

## Security changes

Username validation rejects GraphQL/URL injection characters. Existing accounts migrate from their cache username while preserving the Keychain service/account and local identifier settings. New installations have no hardcoded account. Shared configuration derives both targets' entitlements and Info values from one xcconfig.

Disconnect uses Keychain deletion status checks and removes the cached snapshot. Cross-process file locking and account revisions prevent an older refresh from committing after disconnect/account changes. Already-running network requests and macOS-rendered snapshots cannot be retroactively erased. Remote token revocation is the user's responsibility. A failed operation is reported rather than silently treated as success.

## Verification and limits

Core and temporary-file storage regression tests pass locally. A clean 26-file source copy without Local.xcconfig passes an unsigned Release host/extension build, including extension embedding. The all-local-file credential-pattern scan checked 35 files with zero matches; the publishable-file audit passes. Storage regression tests use temporary files and never delete a live token. The approved desktop UI is preserved; settings add a username input and confirmed Disconnect action. The installed working application and shared data were not replaced or changed during preparation.

Signed release-candidate account switching, migration, Keychain deletion, error recovery and widget reload behavior remain manual integration gates. GitHub Actions is configured but has not run remotely. No full penetration test, notarization, or cross-version runtime certification is claimed.

## Publication procedure

Run `python3 scripts/audit.py` and `scripts/test.sh`. Review all files in `docs/`, including the screenshot. The scanner fails on unexpected files and tracked excluded files, but custom secret formats still require human review. Retain Local.xcconfig privately. Before initializing/importing Git, review the source manifest. Once history exists, scan every commit/blob and revoke any discovered credentials before publication.

Approval is required before push, tags or a public release. See RELEASE_CHECKLIST.md for remaining gates.

## Final release-gate verification — 2026-11-03

Overall: HOLD. No push, publication or release was performed. Intended remote is now DakshChaudhary2668/GitPulse; read-only git ls-remote succeeded and returned no HEAD commit. No remote history was imported.

| Gate | Result | Evidence / limit |
| --- | --- | --- |
| Signed Release host + embedded widget | PASS | Existing developer team; isolated App Group and Keychain suffixes. xcodebuild BUILD SUCCEEDED; strict deep signature verification passed. |
| Signed shared Keychain/App Group access | PASS | Two separately signed probe processes use host and extension entitlements, profiles and Info configurations. Both read the same isolated account/cache and marker credential. Actual WidgetKit process was not launched by this probe. |
| Local account switching | PASS | Synthetic account A replaced with B; A credential absent, cache invalidated before B commit, B avatar marker visible to second process, stale A commit rejected. No GitHub token used. |
| Live GitHub switching | UNVERIFIED | User explicitly selected local tests only. Username/avatar/calendar fetching for two real accounts and resulting widget reload not tested. |
| Disconnect storage deletion | PASS | Intended marker credential removed; snapshot file absent; account empty; second process sees disconnected state; unrelated marker item preserved, then cleaned up separately. |
| Disconnect confirmation UI and desktop rendering | UNVERIFIED | No interactive Disconnect flow or widget timeline rendering tested against disposable credentials. |
| Previous-account data removal | PASS (bounded) | Isolated shared snapshot and targeted Keychain item cleared. Does not certify HTTP caches, system-rendered snapshots, backups, or disk-forensic erasure. No blanket claim that all private bytes disappear. |
| Working installation preserved | PASS (app files) | Hash baseline: installed app unchanged; strict signature valid. Live snapshot changed during test window, but remains decodable with account/calendar/avatar. Probe did not use production storage; cause of live change not conclusively established. |
| Full test suite | PASS | Core calculations, username validation, Codable, legacy migration, cache commits/removal and stale-refresh rejection all pass. |
| Clean portable Release build | PASS | Exact 26-file publication set excluding Local.xcconfig; clean build succeeds and contains embedded widget executable. |
| Workflow requires no personal secrets | PASS (configuration/local reproduction) | macos-15, checkout read-only, standalone tests and CODE_SIGNING_ALLOWED=NO. No secrets references, certificates or signing installation steps. |
| Hosted GitHub Actions execution | UNVERIFIED | No code pushed or workflow triggered remotely. |
| Publication audit | PASS (bounded) | 26-file candidate passes pattern scan; no local Git history exists. Human approval, imported-history review if applicable, license/asset approval and repository security settings remain gates. |

Signed probes were compiled from the current Core/Storage implementation with noncredential marker strings, using isolated storage. They exercise production methods but do not constitute full application UI or WidgetKit end-to-end tests. Probe source, signing/build logs and integrity baseline are local-only under ignored review files or temporary build directories. No changes were installed over the working application.

Remaining blockers: live account-switch/Disconnect/widget UI verification, offline/error integration cases, supported-version/accessibility review, hosted CI, repository private reporting/security settings, and owner approval. These must not be silently marked passed before v1.0.0.

## HOLD follow-up — isolated confirmation UI and cache investigation

Read-only historical diagnostics resolve the cache concern to a strong, bounded explanation: the live snapshot mtime is 04:40:18 IST on November 3, exactly matching production WidgetKit successful timeline reloads at 04:40:17–04:40:18. The production provider fetches and writes a snapshot when refreshing. This is consistent with legitimate refresh activity; no filesystem audit trail proves exclusive attribution. Installed app hashes remain unchanged.

The previous probes retained production bundle identifiers with separate groups. Entitlement inspection confirms only the test App Group and test Keychain group were granted. Negative-access tests under that sandbox denied a read-only production snapshot open (EPERM), denied write access checks, and denied a production-group attribute-only Keychain query with errSecMissingEntitlement (-34018). No snapshot bytes or credential data were requested. This verifies the tested binary's runtime sandbox boundary, not an absolute barrier against a developer able to re-sign code with production entitlements.

After explicit user approval for persistent Apple development provisioning, a separate com.daksh.GitHubPulse.ReleaseGate host and .Widget extension were provisioned and built. They have separate group/Keychain namespaces and were not installed over production. Strict signed-bundle verification passed. No production token was copied.

Actual signed-host UI test with synthetic cache/marker credentials: Disconnect confirmation displayed correct local-removal/revocation text; Cancel preserved the account; confirming Disconnect displayed the empty connection state, cleared username/credential fields and disabled Disconnect. A signed probe verified the empty account, absent snapshot and absent intended credential afterward. The unrelated marker item was subsequently cleaned up. No new confirmation implementation was needed; the existing implementation passed.

Actual test-extension reload remains UNVERIFIED: chronod reported descriptor/reload database FOREIGN KEY constraint failures for the temporary test bundle. No successful test-extension timeline rendering is claimed. This must be tested from a stable installation with disposable credentials before tagging; do not infer extension behavior from the host UI or shared-storage probes. Live username/avatar/calendar switching remains unverified as previously directed by the user. No production refresh was manually requested.

Publication manifest manually reviewed: 26 candidates comprising Swift app/widget sources, Swift test executables, configuration templates/project/plists/entitlements, audit/test scripts, CI YAML, documentation/license and one real connection-state PNG. The PNG contains no account data. Design screenshots, local notes/config, user state, compiled products and signing material are excluded. Pattern audit passes. No local Git history exists; imported history requires a new audit. File lists are unchanged, though README/workflow/audit/checklist content has been updated.

First hosted CI plan is in README. workflow_dispatch is now available; after explicit source-publication approval, record the first run URL, commit and runner toolchain and inspect audit/tests/build/embedding results. No hosted CI success is claimed.

Recommendation: the reviewed source is suitable for publication as an explicitly pre-release/development candidate, subject to owner approval, license ownership approval and repository private-reporting setup. HOLD v1.0.0 tag until live switching, installed test-extension rendering, offline/error behavior and hosted CI pass. HOLD signed binary distribution until those gates plus distribution signing/notarization and installation testing pass. Existing development profiles are not a distribution release.


## Approved source-publication preparation

The owner explicitly approved source-only publication to DakshChaudhary2668/GitPulse, with no tag, release or binary. The existing docs/connection.png slot now contains the owner's supplied reference image, explicitly authorized for README publication. It includes the public username/avatar and historical activity figures; earlier statements that the only screenshot contains no account data are superseded. README identifies it as a historical design reference. The manifest remains exactly 26 paths. A development-stage warning prominently preserves the runtime HOLD status.


## App icon source update

Owner requested an original app icon and push after local preview. Added a native code-drawn charcoal/green pulse-grid mark, its reproducible AppKit generation script, macOS ICNS resource and README PNG preview. No third-party logo or imagery is used. The icon is a bundled design resource, not an application binary distribution. Publication manifest expands from 26 to 29 paths. Local icon preview was visually inspected; Release build must contain AppIcon.icns and CFBundleIconFile. The CI workflow now checks both. Existing runtime release HOLD gates remain in force.
