#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/release_sparkle.sh \
    --app-path <path-to-FracTile.app> \
    --updates-dir <path-to-updates-dir> \
    --download-url-prefix <base-download-url> \
    [--maximum-deltas <count>] \
    [--release-notes <path-to-markdown-or-html>] \
    [--sparkle-bin-dir <path-to-sparkle-bin>]

Example:
  scripts/release_sparkle.sh \
    --app-path ~/Library/Developer/Xcode/DerivedData/.../Build/Products/Release/FracTile.app \
    --updates-dir ./release/updates \
    --download-url-prefix https://github.com/jystringfellow/FracTile/releases/download/v0.0.5 \
    --maximum-deltas 0 \
    --release-notes ./release/notes/v0.0.5.md

This script:
1) zips your .app into updates dir
2) signs the archive with Sparkle's sign_update
3) generates/updates appcast.xml via generate_appcast
EOF
}

APP_PATH=""
UPDATES_DIR=""
DOWNLOAD_URL_PREFIX=""
RELEASE_NOTES_PATH=""
MAXIMUM_DELTAS="0"
SPARKLE_BIN_DIR="${SPARKLE_BIN_DIR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-path)
      APP_PATH="$2"
      shift 2
      ;;
    --updates-dir)
      UPDATES_DIR="$2"
      shift 2
      ;;
    --download-url-prefix)
      DOWNLOAD_URL_PREFIX="$2"
      shift 2
      ;;
    --release-notes)
      RELEASE_NOTES_PATH="$2"
      shift 2
      ;;
    --maximum-deltas)
      MAXIMUM_DELTAS="$2"
      shift 2
      ;;
    --sparkle-bin-dir)
      SPARKLE_BIN_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$APP_PATH" || -z "$UPDATES_DIR" || -z "$DOWNLOAD_URL_PREFIX" ]]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if [[ ! -d "$APP_PATH" || "${APP_PATH##*.}" != "app" ]]; then
  echo "--app-path must point to an existing .app bundle." >&2
  exit 1
fi

if [[ -n "$RELEASE_NOTES_PATH" && ! -f "$RELEASE_NOTES_PATH" ]]; then
  echo "--release-notes file was not found: $RELEASE_NOTES_PATH" >&2
  exit 1
fi

if ! [[ "$MAXIMUM_DELTAS" =~ ^[0-9]+$ ]]; then
  echo "--maximum-deltas must be a non-negative integer." >&2
  exit 1
fi

find_sparkle_bin_dir() {
  local found
  found="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path '*SourcePackages/artifacts/sparkle/Sparkle/bin' -print -quit 2>/dev/null || true)"
  if [[ -n "$found" ]]; then
    printf '%s\n' "$found"
    return
  fi
  printf '%s\n' ""
}

if [[ -z "$SPARKLE_BIN_DIR" ]]; then
  SPARKLE_BIN_DIR="$(find_sparkle_bin_dir)"
fi

if [[ -z "$SPARKLE_BIN_DIR" || ! -x "$SPARKLE_BIN_DIR/sign_update" || ! -x "$SPARKLE_BIN_DIR/generate_appcast" ]]; then
  cat >&2 <<'EOF'
Could not find Sparkle tools.
Set SPARKLE_BIN_DIR or pass --sparkle-bin-dir.
Expected tools:
  - sign_update
  - generate_appcast
EOF
  exit 1
fi

mkdir -p "$UPDATES_DIR"

PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "Missing Info.plist at: $PLIST" >&2
  exit 1
fi

APP_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$PLIST" 2>/dev/null || basename "$APP_PATH" .app)"
SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"

ARCHIVE_NAME="${APP_NAME}-${SHORT_VERSION}-${BUNDLE_VERSION}.zip"
ARCHIVE_PATH="$UPDATES_DIR/$ARCHIVE_NAME"

# Keep parent bundle folder so Sparkle receives a standard app archive layout.
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"

SIGN_OUTPUT="$($SPARKLE_BIN_DIR/sign_update "$ARCHIVE_PATH")"
SIGNATURE="$(printf '%s\n' "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
ARCHIVE_SIZE="$(stat -f%z "$ARCHIVE_PATH")"

if [[ -n "$RELEASE_NOTES_PATH" ]]; then
  notes_ext="${RELEASE_NOTES_PATH##*.}"
  if [[ "$notes_ext" != "md" && "$notes_ext" != "html" && "$notes_ext" != "txt" ]]; then
    echo "Release notes should be .md, .html, or .txt" >&2
    exit 1
  fi
  cp "$RELEASE_NOTES_PATH" "$UPDATES_DIR/${ARCHIVE_NAME%.*}.$notes_ext"
fi

DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX%/}"

$SPARKLE_BIN_DIR/generate_appcast \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --maximum-deltas "$MAXIMUM_DELTAS" \
  "$UPDATES_DIR"

cat <<EOF

Release artifacts prepared.

App:                $APP_PATH
Version:            $SHORT_VERSION ($BUNDLE_VERSION)
Archive:            $ARCHIVE_PATH
Archive size:       $ARCHIVE_SIZE
EdDSA signature:    $SIGNATURE
Appcast:            $UPDATES_DIR/appcast.xml

Suggested GitHub release upload list:
- $ARCHIVE_NAME
- appcast.xml
- old_updates/ (optional; skip if not publishing deltas)

Reminder:
- Ensure SUFeedURL points to the published appcast.xml URL.
- Upload appcast.xml to the stable feed location before/with release asset publication.
- This run used maximum deltas: $MAXIMUM_DELTAS
EOF
