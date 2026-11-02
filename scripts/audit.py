#!/usr/bin/env python3
"""Fail closed on unexpected publishable files; never print matching secret values."""
import pathlib, re, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[1]
allowed_roots = {'Sources', 'Widget', 'Tests', 'Config', 'scripts', 'docs', '.github'}
allowed_top = {'.gitignore', 'README.md', 'LICENSE', 'CONTRIBUTING.md', 'SECURITY.md', 'CHANGELOG.md', 'RELEASE_CHECKLIST.md', 'AUDIT.md', 'GitHubPulse.plist', 'PulseWidget.plist', 'GitHubPulse.entitlements', 'PulseWidget.entitlements'}
def excluded(p):
    return p.parts[0] in {'.git', '.release-local', 'Design', 'build', '.build', 'DerivedData'} or 'xcuserdata' in p.parts or p.as_posix() == 'Config/Local.xcconfig'
def candidate(p):
    return p.as_posix() in allowed_top or p.parts[0] in allowed_roots or p.as_posix() == 'GitHubPulse.xcodeproj/project.pbxproj' or ('xcshareddata' in p.parts and p.suffix == '.xcscheme')
patterns = [rb'gh[pousr]_[A-Za-z0-9]{20,}', rb'github_pat_[A-Za-z0-9_]{20,}', rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', rb'AKIA[A-Z0-9]{16}', rb'/Users/[^/\s<]+/', rb'DEVELOPMENT_TEAM\s*=\s*[A-Z0-9]{10}\s*;', rb'[A-Za-z0-9._%+-]+@(?:gmail|icloud|outlook)\.com']
failures=[]; files=[]
for p in root.rglob('*'):
    rel=p.relative_to(root)
    if excluded(rel) or not p.is_file(): continue
    if p.is_symlink() or not candidate(rel): failures.append(str(rel)+': unexpected file'); continue
    if p.suffix in {'.p12','.pem','.key','.cer','.provisionprofile','.mobileprovision'}: failures.append(str(rel)+': signing artifact')
    data=p.read_bytes()
    # This scanner contains the denylist itself, never application credentials.
    if rel.as_posix() != 'scripts/audit.py' and any(re.search(pattern,data) for pattern in patterns): failures.append(str(rel)+': sensitive pattern')
    files.append(str(rel))
# Ignored files must not already be tracked when this becomes a Git repository.
result=subprocess.run(['git','ls-files','-z'],cwd=root,capture_output=True)
if result.returncode == 0:
    for path in result.stdout.decode().split('\0'):
        if path and (excluded(pathlib.Path(path)) or not candidate(pathlib.Path(path))): failures.append(path+': excluded/unexpected file is tracked')
print('\n'.join(failures) if failures else f'PASS: {len(files)} publishable files checked; excluded local files not included.')
if __name__ == "__main__":
    sys.exit(bool(failures))
