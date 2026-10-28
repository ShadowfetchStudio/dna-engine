#!/bin/bash
set -euo pipefail

# Package a built DNA Engine.app into a compressed UDZO disk image.
# macOS-only (ditto + hdiutil). Does not sign, notarize, or upload.
#
# Usage:
#   Tools/package_dmg.sh <app-bundle> <output.dmg> [volume-name]

umask 077

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

note() {
  printf '==> %s\n' "$*"
}

[ "$#" -ge 2 ] || fail "usage: $0 <app-bundle> <output.dmg> [volume-name]"

APP="$1"
DMG="$2"
VOLNAME="${3:-DNA Engine}"

[ -d "$APP" ] || fail "app bundle not found: $APP"
[ -x "$APP/Contents/MacOS/DNAEngine" ] || fail "app executable missing: $APP/Contents/MacOS/DNAEngine"

case "$DMG" in
  *.dmg) ;;
  *) fail "output path must end in .dmg: $DMG" ;;
esac

for command_name in ditto hdiutil; do
  command -v "$command_name" >/dev/null 2>&1 || fail "required command not found: $command_name"
done

# Keep the scratch folder off the image: never write the .dmg inside STAGE.
STAGE="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/dnaengine-dmg.XXXXXX")"
cleanup() {
  case "${STAGE:-}" in
    "${TMPDIR:-/tmp}"/dnaengine-dmg.*) /bin/rm -rf -- "$STAGE" ;;
  esac
}
trap cleanup EXIT INT TERM

note "Staging DMG contents"
/usr/bin/ditto "$APP" "$STAGE/DNA Engine.app"
/bin/ln -s /Applications "$STAGE/Applications"

DMG_DIR="$(/usr/bin/dirname "$DMG")"
/bin/mkdir -p "$DMG_DIR"
ABS_DMG="$(cd "$DMG_DIR" && pwd)/$(/usr/bin/basename "$DMG")"

note "Creating compressed disk image"
# -o keeps hdiutil from appending a second .dmg suffix.
/usr/bin/hdiutil create \
  -volname "$VOLNAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$ABS_DMG"

[ -f "$ABS_DMG" ] || fail "DMG was not created: $ABS_DMG"
note "DMG ready: $ABS_DMG ($(/usr/bin/du -h "$ABS_DMG" | /usr/bin/awk '{print $1}'))"
