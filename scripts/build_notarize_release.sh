#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/build_notarize_release.sh \
    --keychain-profile <notary-profile> \
    [--project <xcodeproj>] \
    [--scheme <scheme>] \
    [--configuration <config>] \
    [--team-id <apple-team-id>] \
    [--output-dir <release-dir>] \
    [--export-options-plist <plist-path>]

Defaults:
  --project      app/FracTile.xcodeproj
  --scheme       FracTile
  --configuration Release
  --team-id      6T7K8KMSN3
  --output-dir   ./release

This script:
1) archives and exports a Developer ID signed app
2) submits the exported app for notarization and waits
3) staples and validates notarization ticket

Output app path:
  <output-dir>/export/FracTile.app
EOF
}

PROJECT_PATH="app/FracTile.xcodeproj"
SCHEME_NAME="FracTile"
CONFIGURATION="Release"
TEAM_ID="6T7K8KMSN3"
OUTPUT_DIR="./release"
KEYCHAIN_PROFILE=""
EXPORT_OPTIONS_PLIST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --scheme)
      SCHEME_NAME="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --keychain-profile)
      KEYCHAIN_PROFILE="$2"
      shift 2
      ;;
    --export-options-plist)
      EXPORT_OPTIONS_PLIST="$2"
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

if [[ -z "$KEYCHAIN_PROFILE" ]]; then
  echo "--keychain-profile is required." >&2
  usage
  exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Project not found: $PROJECT_PATH" >&2
  exit 1
fi

if [[ -z "$EXPORT_OPTIONS_PLIST" ]]; then
  EXPORT_OPTIONS_PLIST="$OUTPUT_DIR/ExportOptions-DeveloperID.plist"
fi

mkdir -p "$OUTPUT_DIR"
ARCHIVE_PATH="$OUTPUT_DIR/FracTile.xcarchive"
EXPORT_PATH="$OUTPUT_DIR/export"
NOTARY_ZIP_PATH="$OUTPUT_DIR/notary-input.zip"

if [[ ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
  cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF
fi

xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

APP_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -type d -name '*.app' | head -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "No .app found in export path: $EXPORT_PATH" >&2
  exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARY_ZIP_PATH"

xcrun notarytool submit "$NOTARY_ZIP_PATH" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait

xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

cat <<EOF

Release build and notarization completed.

Archive:     $ARCHIVE_PATH
Export:      $EXPORT_PATH
App:         $APP_PATH
Notary zip:  $NOTARY_ZIP_PATH

Next:
1) Run scripts/release_sparkle.sh using this app path.
2) Upload generated archive to GitHub Releases.
3) Publish appcast with scripts/publish_appcast_pages.sh.
EOF
