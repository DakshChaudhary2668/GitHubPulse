# Security policy

The proposed v1.0.x line will receive security fixes after release. No version is currently published by this project-preparation process.

Report vulnerabilities privately through the repository's Security → Report a vulnerability when private reporting is enabled. If it is unavailable, do not post exploit details or credentials in a public issue; wait for the maintainer to establish a private channel. Enabling private reporting is a release prerequisite. No response SLA is promised.

Include affected version, impact and a minimal reproduction using disposable data. Never include tokens or private keys. Revoke compromised GitHub tokens immediately.

Tokens reside in the macOS shared data-protection Keychain. The shared cache contains activity/avatar data, not tokens. Disconnect removes the local token and cache, but does not revoke the token remotely or instantly erase system-rendered widget snapshots. Deleting the app alone does not guarantee Keychain removal. The application makes HTTPS requests to GitHub's API and avatar host and has no analytics service.

Pattern scanning cannot prove the absence of all sensitive information. Review the publication manifest, images and Git history before each release. See AUDIT.md for scope and remaining integration checks.
