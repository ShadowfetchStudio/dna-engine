#!/bin/bash
set -euo pipefail

# DNA Engine private/local release builder.
#
# Build only (never touches /Applications):
#   BUILD_ONLY=1 ./build.sh
#
# Explicit local install (creates a verified backup and atomically swaps apps):
#   INSTALL=1 ./build.sh
#
# VERSION and BUILD_NUMBER are read from the checked-in files of the same
# names. Environment values may override them for an intentional candidate.
#
# Optional signing knobs (used by .github/workflows/release.yml):
#   SIGNING_IDENTITY   — exact codesign identity; otherwise auto-detected
#   SIGN_TIMESTAMP=1   — embed Apple's secure timestamp (required to notarize)
#   REQUIRE_UNIVERSAL=1 — fail if an x86_64 slice cannot be produced

umask 077

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$PROJECT_DIR/Sources"
RES="$PROJECT_DIR/Resources"
TOOLS="$PROJECT_DIR/Tools"
BUILD="$PROJECT_DIR/build"
APP_NAME="DNA Engine"
BIN_NAME="DNAEngine"
BUNDLE_ID="ai.shadowfetch.dnaengine"
MIN_MACOS="14.0"
INSTALL_PATH="/Applications/$APP_NAME.app"
INFO_TEMPLATE="$RES/Info.plist.in"
ATOMIC_SWAP_SOURCE="$TOOLS/atomic_swap.c"
VERSION_FILE="$PROJECT_DIR/VERSION"
BUILD_NUMBER_FILE="$PROJECT_DIR/BUILD_NUMBER"

VERSION="${VERSION:-$(/usr/bin/tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || true)}"
BUILD_NUMBER="${BUILD_NUMBER:-$(/usr/bin/tr -d '[:space:]' < "$BUILD_NUMBER_FILE" 2>/dev/null || true)}"
BUILD_ONLY="${BUILD_ONLY:-0}"
INSTALL="${INSTALL:-0}"
REQUIRE_UNIVERSAL="${REQUIRE_UNIVERSAL:-0}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
SIGN_TIMESTAMP="${SIGN_TIMESTAMP:-0}"
BACKUP_ROOT="${DNA_ENGINE_BACKUP_ROOT:-${HOME}/Library/Application Support/DNAEngine Release Backups}"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '==> %s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_file() {
  [ -f "$1" ] || fail "required file not found: $1"
}

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1"
}

validate_inputs() {
  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] \
    || fail "VERSION must be 2 or 3 dot-separated integers (example: 2.2.0)"
  [[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]] \
    || fail "BUILD_NUMBER must be a positive integer"

  case "$BUILD_ONLY" in 0|1) ;; *) fail "BUILD_ONLY must be 0 or 1" ;; esac
  case "$INSTALL" in 0|1) ;; *) fail "INSTALL must be 0 or 1" ;; esac
  case "$REQUIRE_UNIVERSAL" in 0|1) ;; *) fail "REQUIRE_UNIVERSAL must be 0 or 1" ;; esac
  case "$SIGN_TIMESTAMP" in 0|1) ;; *) fail "SIGN_TIMESTAMP must be 0 or 1" ;; esac

  if [ "$BUILD_ONLY" = "$INSTALL" ]; then
    fail "choose exactly one mode: BUILD_ONLY=1 or INSTALL=1"
  fi

  require_file "$INFO_TEMPLATE"
  require_file "$ATOMIC_SWAP_SOURCE"
  require_file "$VERSION_FILE"
  require_file "$BUILD_NUMBER_FILE"
  require_file "$TOOLS/run_checks.sh"
  require_file "$TOOLS/run_vault_checks.sh"
  require_file "$RES/knowledge.json"
  require_file "$RES/reference_panel.json"
  require_file "$RES/draw_icon.swift"
}

resolve_signing_identity() {
  local identities selected
  identities="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null || true)"

  if [ -n "$SIGNING_IDENTITY" ]; then
    printf '%s\n' "$identities" | /usr/bin/grep -F -- "$SIGNING_IDENTITY" >/dev/null \
      || fail "SIGNING_IDENTITY is not a valid identity in the current keychain: $SIGNING_IDENTITY"
    RESOLVED_SIGNING_IDENTITY="$SIGNING_IDENTITY"
    SIGNING_MODE="local identity"
    return
  fi

  selected="$(printf '%s\n' "$identities" | /usr/bin/awk '/Developer ID Application:/ { gsub(/[()]/, "", $2); print $2; exit }')"
  if [ -z "$selected" ]; then
    selected="$(printf '%s\n' "$identities" | /usr/bin/awk '/Apple Development:|Mac Developer:/ { gsub(/[()]/, "", $2); print $2; exit }')"
  fi

  if [ -n "$selected" ]; then
    RESOLVED_SIGNING_IDENTITY="$selected"
    SIGNING_MODE="local identity"
  else
    RESOLVED_SIGNING_IDENTITY="-"
    SIGNING_MODE="ad hoc fallback"
  fi
}

verify_arches() {
  local binary="$1"
  local actual count expected arch
  actual="$(/usr/bin/lipo -archs "$binary")"
  count=0
  for expected in "${ARCHS[@]}"; do
    printf '%s\n' "$actual" | /usr/bin/grep -Eq "(^|[[:space:]])${expected}([[:space:]]|$)" \
      || fail "missing required architecture $expected in $binary (found: $actual)"
    count=$((count + 1))
  done
  set -- $actual
  [ "$#" -eq "$count" ] || fail "unexpected architecture set in $binary (found: $actual)"
  for arch in "$@"; do
    case " ${ARCHS[*]} " in
      *" $arch "*) ;;
      *) fail "unexpected architecture $arch in $binary" ;;
    esac
  done
}

verify_required_links() {
  local binary="$1"
  local links framework
  links="$(/usr/bin/otool -L "$binary")"
  for framework in SwiftUI AppKit Foundation Combine UniformTypeIdentifiers WebKit Security CryptoKit; do
    printf '%s\n' "$links" | /usr/bin/grep -F "/${framework}.framework/" >/dev/null \
      || fail "required framework is not linked: $framework"
  done
  printf '%s\n' "$links" | /usr/bin/grep -Eq '/usr/lib/libz(\.[0-9]+)*\.dylib' \
    || fail "required zlib runtime is not linked"
}

verify_app() {
  local app="$1"
  local plist="$app/Contents/Info.plist"
  local binary="$app/Contents/MacOS/$BIN_NAME"
  local sign_info executable_count

  [ -d "$app" ] || fail "app bundle missing: $app"
  [ -x "$binary" ] || fail "app executable missing or not executable: $binary"
  /usr/bin/plutil -lint "$plist" >/dev/null

  [ "$(plist_value "$plist" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
    || fail "bundle identifier verification failed"
  [ "$(plist_value "$plist" CFBundleShortVersionString)" = "$VERSION" ] \
    || fail "bundle version verification failed"
  [ "$(plist_value "$plist" CFBundleVersion)" = "$BUILD_NUMBER" ] \
    || fail "bundle build-number verification failed"
  [ "$(plist_value "$plist" LSMinimumSystemVersion)" = "$MIN_MACOS" ] \
    || fail "minimum-system-version verification failed"
  [ "$(plist_value "$plist" CFBundleExecutable)" = "$BIN_NAME" ] \
    || fail "bundle executable-name verification failed"

  /usr/bin/cmp -s "$RES/knowledge.json" "$app/Contents/Resources/knowledge.json" \
    || fail "knowledge.json differs from the validated source resource"
  /usr/bin/cmp -s "$RES/reference_panel.json" "$app/Contents/Resources/reference_panel.json" \
    || fail "reference_panel.json differs from the validated source resource"

  executable_count="$(/usr/bin/find "$app/Contents" -type f -perm -111 -print | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
  [ "$executable_count" = "1" ] || fail "expected exactly one executable file, found $executable_count"

  verify_arches "$binary"
  verify_required_links "$binary"
  /usr/bin/codesign --verify --deep --strict --verbose=4 --all-architectures "$app"
  sign_info="$(/usr/bin/codesign -dvvv "$app" 2>&1)"
  printf '%s\n' "$sign_info" | /usr/bin/grep -F "Identifier=$BUNDLE_ID" >/dev/null \
    || fail "code-sign identifier verification failed"
  printf '%s\n' "$sign_info" | /usr/bin/grep -Eq 'flags=.*runtime' \
    || fail "hardened runtime flag is missing from the signature"
}

archive_existing_app() {
  local existing="$1"
  local archive_root="$2"
  local old_version old_build stamp archive_path

  old_version="$(plist_value "$existing/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || printf 'unknown')"
  old_build="$(plist_value "$existing/Contents/Info.plist" CFBundleVersion 2>/dev/null || printf 'unknown')"
  stamp="$(/bin/date -u '+%Y%m%dT%H%M%SZ')"
  archive_path="$archive_root/$APP_NAME-$old_version-$old_build-$stamp.app"
  [ ! -e "$archive_path" ] || archive_path="$archive_root/$APP_NAME-$old_version-$old_build-$stamp-$$.app"

  [ ! -L "$archive_root" ] || fail "backup root must not be a symbolic link: $archive_root"
  /bin/mkdir -p "$archive_root"
  /bin/chmod 700 "$archive_root"
  /usr/bin/ditto "$existing" "$archive_path"
  /usr/bin/diff -qr "$existing" "$archive_path" >/dev/null \
    || fail "backup verification failed: $archive_path"
  LAST_BACKUP_PATH="$archive_path"
}

atomic_replace() {
  local staged="$1"
  local destination="$2"
  local backup_root="$3"

  if [ ! -e "$destination" ]; then
    /bin/mv "$staged" "$destination"
    return
  fi

  archive_existing_app "$destination" "$backup_root"
  "$ATOMIC_SWAP_BIN" "$staged" "$destination"

  # Run verification in a subshell so a failing gate can trigger the rollback
  # below instead of exiting the release process before the swap is undone.
  if ! ( verify_app "$destination" ); then
    printf 'Replacement verification failed; restoring previous app atomically.\n' >&2
    "$ATOMIC_SWAP_BIN" "$staged" "$destination" || fail "automatic rollback failed; previous app remains at $staged"
    fail "new app failed verification after atomic swap; previous app restored"
  fi

  case "$staged" in
    "$BUILD"/.DNA\ Engine.publish.*|/Applications/.DNA\ Engine.install.*)
      /bin/rm -rf -- "$staged"
      ;;
    *)
      fail "refusing to remove unexpected post-swap path: $staged"
      ;;
  esac
}

write_checksum_manifest() {
  local app="$1"
  local manifest="$2"
  (
    cd "$app"
    /usr/bin/find Contents -type f -print | LC_ALL=C /usr/bin/sort \
      | while IFS= read -r file; do /usr/bin/shasum -a 256 "$file"; done
  ) > "$manifest"
}

write_input_manifest() {
  local manifest="$1"
  (
    cd "$PROJECT_DIR"
    { /usr/bin/find Sources Resources Tools -type f \
      ! -path '*/__pycache__/*' \
      ! -name '*.pyc' \
      ! -name 'icon-1024.png' \
      -print; printf '%s\n' VERSION BUILD_NUMBER build.sh; } \
      | LC_ALL=C /usr/bin/sort \
      | while IFS= read -r file; do /usr/bin/shasum -a 256 "$file"; done
  ) > "$manifest"
}

for command_name in xcrun python3 swift sips iconutil plutil codesign lipo otool ditto security; do
  require_command "$command_name"
done
validate_inputs

cd "$PROJECT_DIR"

WORK_ROOT="$(/usr/bin/mktemp -d "$PROJECT_DIR/.dnaengine-build.XXXXXX")"
cleanup() {
  case "${WORK_ROOT:-}" in
    "$PROJECT_DIR"/.dnaengine-build.*) /bin/rm -rf -- "$WORK_ROOT" ;;
  esac
}
trap cleanup EXIT INT TERM

APP_STAGE="$WORK_ROOT/$APP_NAME.app"
ATOMIC_SWAP_BIN="$WORK_ROOT/atomic_swap"
/bin/mkdir -p "$APP_STAGE/Contents/MacOS" "$APP_STAGE/Contents/Resources"

note "Preflight checks"
/bin/bash "$TOOLS/run_checks.sh"
/bin/bash "$TOOLS/run_vault_checks.sh"

note "Build-support verification"
SDK_PATH="$(/usr/bin/xcrun --sdk macosx --show-sdk-path)"
SWIFTC="$(/usr/bin/xcrun --sdk macosx --find swiftc)"
CLANG="$(/usr/bin/xcrun --sdk macosx --find clang)"
"$CLANG" -isysroot "$SDK_PATH" -std=c11 -Wall -Wextra -Werror -mmacosx-version-min="$MIN_MACOS" \
  "$ATOMIC_SWAP_SOURCE" -o "$ATOMIC_SWAP_BIN"
SWAP_TEST_ROOT="$WORK_ROOT/atomic-swap-self-test"
/bin/mkdir "$SWAP_TEST_ROOT" "$SWAP_TEST_ROOT/new.app" "$SWAP_TEST_ROOT/old.app"
/usr/bin/touch "$SWAP_TEST_ROOT/new.app/new" "$SWAP_TEST_ROOT/old.app/old"
"$ATOMIC_SWAP_BIN" "$SWAP_TEST_ROOT/new.app" "$SWAP_TEST_ROOT/old.app"
[ -f "$SWAP_TEST_ROOT/old.app/new" ] && [ -f "$SWAP_TEST_ROOT/new.app/old" ] \
  || fail "atomic swap helper self-test failed"
/bin/rm -rf -- "$SWAP_TEST_ROOT"

INPUT_MANIFEST="$WORK_ROOT/release-inputs.sha256"
write_input_manifest "$INPUT_MANIFEST"

ARCHS=(arm64)
if "$SWIFTC" -sdk "$SDK_PATH" -target "x86_64-apple-macos$MIN_MACOS" -print-target-info >/dev/null 2>&1; then
  ARCHS+=(x86_64)
elif [ "$REQUIRE_UNIVERSAL" = "1" ]; then
  fail "x86_64 cross-compilation is unavailable and REQUIRE_UNIVERSAL=1"
else
  printf 'WARNING: x86_64 target unavailable; producing arm64-only private build.\n' >&2
fi

SOURCE_FILES=()
while IFS= read -r source_file; do
  SOURCE_FILES+=("$source_file")
done < <(/usr/bin/find "$SRC" -type f -name '*.swift' -print | LC_ALL=C /usr/bin/sort)
[ "${#SOURCE_FILES[@]}" -gt 0 ] || fail "no Swift sources found"

note "Deterministic resources"
ICON_PNG="$WORK_ROOT/icon-1024.png"
ICONSET="$WORK_ROOT/AppIcon.iconset"
/usr/bin/swift "$RES/draw_icon.swift" "$ICON_PNG"
/bin/mkdir -p "$ICONSET"
/usr/bin/sips -z 16 16 "$ICON_PNG" --out "$ICONSET/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32 "$ICON_PNG" --out "$ICONSET/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64 "$ICON_PNG" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128 "$ICON_PNG" --out "$ICONSET/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256 "$ICON_PNG" --out "$ICONSET/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512 "$ICON_PNG" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
/bin/cp "$ICON_PNG" "$ICONSET/icon_512x512@2x.png"
/usr/bin/iconutil -c icns "$ICONSET" -o "$APP_STAGE/Contents/Resources/AppIcon.icns"
/bin/cp "$RES/knowledge.json" "$APP_STAGE/Contents/Resources/knowledge.json"
/bin/cp "$RES/reference_panel.json" "$APP_STAGE/Contents/Resources/reference_panel.json"
/usr/bin/sed -e "s/__VERSION__/$VERSION/g" -e "s/__BUILD_NUMBER__/$BUILD_NUMBER/g" \
  "$INFO_TEMPLATE" > "$APP_STAGE/Contents/Info.plist"
/usr/bin/plutil -lint "$APP_STAGE/Contents/Info.plist" >/dev/null

note "Compile ${ARCHS[*]} with warnings as errors"
ARCH_BINARIES=()
for arch in "${ARCHS[@]}"; do
  arch_binary="$WORK_ROOT/$BIN_NAME.$arch"
  "$SWIFTC" \
    -sdk "$SDK_PATH" \
    -O \
    -whole-module-optimization \
    -warnings-as-errors \
    -target "$arch-apple-macos$MIN_MACOS" \
    -parse-as-library \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework Combine \
    -framework UniformTypeIdentifiers \
    -framework WebKit \
    -framework Security \
    -framework CryptoKit \
    -lz \
    -o "$arch_binary" \
    "${SOURCE_FILES[@]}"
  ARCH_BINARIES+=("$arch_binary")
done

if [ "${#ARCH_BINARIES[@]}" -eq 2 ]; then
  /usr/bin/lipo -create "${ARCH_BINARIES[@]}" -output "$APP_STAGE/Contents/MacOS/$BIN_NAME"
else
  /bin/cp "${ARCH_BINARIES[0]}" "$APP_STAGE/Contents/MacOS/$BIN_NAME"
fi
/bin/chmod 755 "$APP_STAGE/Contents/MacOS/$BIN_NAME"

resolve_signing_identity
# Ad-hoc signatures cannot use Apple's timestamp service. A secure timestamp is
# required for Developer ID notarization; CI sets SIGN_TIMESTAMP=1 for that path.
if [ "$RESOLVED_SIGNING_IDENTITY" != "-" ] && [ "$SIGN_TIMESTAMP" = "1" ]; then
  CODESIGN_TIMESTAMP=(--timestamp)
  TIMESTAMP_MODE="Apple secure timestamp"
else
  CODESIGN_TIMESTAMP=(--timestamp=none)
  TIMESTAMP_MODE="no timestamp"
fi
note "Sign with hardened runtime ($SIGNING_MODE: $RESOLVED_SIGNING_IDENTITY; $TIMESTAMP_MODE)"
/usr/bin/codesign --force --sign "$RESOLVED_SIGNING_IDENTITY" --options runtime "${CODESIGN_TIMESTAMP[@]}" "$APP_STAGE"

note "Strict artifact verification"
verify_app "$APP_STAGE"
POSTBUILD_INPUT_MANIFEST="$WORK_ROOT/release-inputs-postbuild.sha256"
write_input_manifest "$POSTBUILD_INPUT_MANIFEST"
/usr/bin/cmp -s "$INPUT_MANIFEST" "$POSTBUILD_INPUT_MANIFEST" \
  || fail "release inputs changed during the build; rerun against a quiescent source tree"

note "Publish validated build artifact"
/bin/mkdir -p "$BUILD"
FINAL_APP="$BUILD/$APP_NAME.app"
PUBLISH_STAGE="$BUILD/.DNA Engine.publish.$$.app"
[ ! -e "$PUBLISH_STAGE" ] && [ ! -L "$PUBLISH_STAGE" ] \
  || fail "unexpected publish staging path already exists: $PUBLISH_STAGE"
/usr/bin/ditto "$APP_STAGE" "$PUBLISH_STAGE"
verify_app "$PUBLISH_STAGE"
if [ -e "$FINAL_APP" ]; then
  atomic_replace "$PUBLISH_STAGE" "$FINAL_APP" "$BUILD/Previous Builds"
else
  /bin/mv "$PUBLISH_STAGE" "$FINAL_APP"
fi
verify_app "$FINAL_APP"
CHECKSUM_MANIFEST="$BUILD/$APP_NAME.app.sha256"
write_checksum_manifest "$FINAL_APP" "$CHECKSUM_MANIFEST"

if [ "$BUILD_ONLY" = "1" ]; then
  printf '\nBuild-only validation passed.\nArtifact: %s\nChecksums: %s\nArchitectures: %s\nVersion: %s (%s)\nSigning: %s\n' \
    "$FINAL_APP" "$CHECKSUM_MANIFEST" "${ARCHS[*]}" "$VERSION" "$BUILD_NUMBER" "$SIGNING_MODE"
  exit 0
fi

note "Explicit private install"
if /usr/bin/pgrep -x "$BIN_NAME" >/dev/null 2>&1; then
  fail "$APP_NAME is running; quit it manually, then repeat with INSTALL=1"
fi
[ -d /Applications ] || fail "/Applications is unavailable"
[ -w /Applications ] || fail "/Applications is not writable by the current user"

INSTALL_STAGE="/Applications/.DNA Engine.install.$$.$RANDOM.app"
[ ! -e "$INSTALL_STAGE" ] && [ ! -L "$INSTALL_STAGE" ] \
  || fail "unexpected install staging path already exists: $INSTALL_STAGE"
/usr/bin/ditto "$FINAL_APP" "$INSTALL_STAGE"
verify_app "$INSTALL_STAGE"

LAST_BACKUP_PATH=""
if [ -e "$INSTALL_PATH" ]; then
  atomic_replace "$INSTALL_STAGE" "$INSTALL_PATH" "$BACKUP_ROOT"
else
  /bin/mv "$INSTALL_STAGE" "$INSTALL_PATH"
  verify_app "$INSTALL_PATH"
fi

printf '\nPrivate install passed all gates.\nInstalled: %s\nBackup: %s\nArchitectures: %s\nVersion: %s (%s)\nSigning: %s\n' \
  "$INSTALL_PATH" "${LAST_BACKUP_PATH:-none; first install}" "${ARCHS[*]}" "$VERSION" "$BUILD_NUMBER" "$SIGNING_MODE"
