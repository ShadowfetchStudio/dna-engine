#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${TMPDIR:-/tmp}/dnaengine-vault-check"

swiftc \
  -warnings-as-errors \
  -D DNAENGINE_VAULT_TESTING \
  -target arm64-apple-macos14.0 \
  -parse-as-library \
  -framework AppKit \
  -framework Combine \
  "$ROOT/Sources/Paths.swift" \
  "$ROOT/Sources/PrivateVault.swift" \
  "$ROOT/Sources/PrivateWorkspaceStore.swift" \
  "$ROOT/Sources/WorkspaceActivityMonitor.swift" \
  "$ROOT/Tools/VaultCheckMain.swift" \
  -o "$OUT"

"$OUT"
