# Contributing

Build with Swift 6 and Xcode on macOS. Keep changes focused and preserve the native SwiftUI/WidgetKit architecture. Use an ignored Local.xcconfig for signing; never commit personal certificates, profiles, tokens or cached activity.

Before a pull request, run `scripts/test.sh`, `python3 scripts/audit.py`, and the unsigned Release build in README. Describe behavior changes, verification and remaining runtime limitations. Changes to storage/authentication need signed tests with a disposable account, including account switching, disconnect, offline behavior and overlapping refreshes. Never use a contributor's live credential in tests.

Use issues for reproducible bugs with macOS/Xcode versions and sanitized diagnostics. Use the private process in SECURITY.md for vulnerabilities. Do not attach full unified logs or account caches.
