#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
swiftc -swift-version 6 -module-cache-path "$test_dir/modules" Sources/Core.swift Tests/main.swift -o "$test_dir/tests"
"$test_dir/tests"
swiftc -swift-version 6 -module-cache-path "$test_dir/modules" Sources/Core.swift Sources/Storage.swift Tests/StorageChecks.swift -o "$test_dir/storage-tests"
"$test_dir/storage-tests"
