#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/release_all.sh \
    --marketing-version <x.y.z> \
    --keychain-profile <notary-profile> \
    [--build-version <integer>] \
    [--team-id <apple-team-id>] \
    [--git-remote <remote>] \
    [--release-tag <tag>] \
    [--download-url-prefix <url>] \
    [--release-notes <notes-file>] \
    [--output-dir <release-dir>] \
    [--updates-dir <updates-dir>] \
    [--pages-branch <branch>] \
    [--pages-site-subdir <subdir>] \
    [--sparkle-bin-dir <path>] \
    [--maximum-deltas <count>] \
    [--dry-run] \
    [--skip-git-push] \
    [--skip-pages-publish] \
    [--yes]

Defaults:
  --team-id             6T7K8KMSN3
  --git-remote          origin
  --release-tag         v<marketing-version>
  --output-dir          ./release
  --updates-dir         ./release/updates
  --pages-branch        gh-pages
  --pages-site-subdir   .
  --maximum-deltas      0

This script performs the full release flow:
1) bumps MARKETING_VERSION and CURRENT_PROJECT_VERSION
2) commits and tags the release
3) builds + notarizes the app
4) creates Sparkle archive + appcast metadata
5) pauses for GitHub Release upload, then publishes appcast to Pages

Dry run:
  --dry-run prints the computed version/tag/URLs and planned commands,
  then exits before making changes.
EOF
}

PROJECT_PBXPROJ="app/FracTile.xcodeproj/project.pbxproj"
TEAM_ID="6T7K8KMSN3"
GIT_REMOTE="origin"
OUTPUT_DIR="./release"
UPDATES_DIR="./release/updates"
PAGES_BRANCH="gh-pages"
PAGES_SITE_SUBDIR="."
MAXIMUM_DELTAS="0"
MARKETING_VERSION=""
BUILD_VERSION=""
KEYCHAIN_PROFILE=""
RELEASE_TAG=""
DOWNLOAD_URL_PREFIX=""
RELEASE_NOTES_PATH=""
SPARKLE_BIN_DIR=""
SKIP_GIT_PUSH="false"
SKIP_PAGES_PUBLISH="false"
YES_MODE="false"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --marketing-version)
      MARKETING_VERSION="$2"
      shift 2
      ;;
    --build-version)
      BUILD_VERSION="$2"
      shift 2
      ;;
    --keychain-profile)
      KEYCHAIN_PROFILE="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --git-remote)
      GIT_REMOTE="$2"
      shift 2
      ;;
    --release-tag)
      RELEASE_TAG="$2"
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
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --updates-dir)
      UPDATES_DIR="$2"
      shift 2
      ;;
    --pages-branch)
      PAGES_BRANCH="$2"
      shift 2
      ;;
    --pages-site-subdir)
      PAGES_SITE_SUBDIR="$2"
      shift 2
      ;;
    --sparkle-bin-dir)
      SPARKLE_BIN_DIR="$2"
      shift 2
      ;;
    --maximum-deltas)
      MAXIMUM_DELTAS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --skip-git-push)
      SKIP_GIT_PUSH="true"
      shift
      ;;
    --skip-pages-publish)
      SKIP_PAGES_PUBLISH="true"
      shift
      ;;
    --yes)
      YES_MODE="true"
      shift
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

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

require_tool git
require_tool python3

if [[ -z "$MARKETING_VERSION" || -z "$KEYCHAIN_PROFILE" ]]; then
  echo "--marketing-version and --keychain-profile are required." >&2
  usage
  exit 1
fi

if [[ ! "$MARKETING_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "--marketing-version must use semantic style (for example 0.0.5)." >&2
  exit 1
fi

if ! [[ "$MAXIMUM_DELTAS" =~ ^[0-9]+$ ]]; then
  echo "--maximum-deltas must be a non-negative integer." >&2
  exit 1
fi

if [[ ! -f "$PROJECT_PBXPROJ" ]]; then
  echo "Missing project file: $PROJECT_PBXPROJ" >&2
  exit 1
fi

if [[ -n "$RELEASE_NOTES_PATH" && ! -f "$RELEASE_NOTES_PATH" ]]; then
  echo "Release notes file not found: $RELEASE_NOTES_PATH" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Run this script from inside the repository." >&2
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" && "$DRY_RUN" != "true" ]]; then
  echo "Releases should be cut from main. Current branch: $CURRENT_BRANCH" >&2
  exit 1
fi
if [[ "$CURRENT_BRANCH" != "main" && "$DRY_RUN" == "true" ]]; then
  echo "Dry run warning: expected branch 'main', found '$CURRENT_BRANCH'." >&2
fi

if [[ -n "$(git status --porcelain)" && "$DRY_RUN" != "true" ]]; then
  echo "Working tree must be clean before running release_all.sh" >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" && "$DRY_RUN" == "true" ]]; then
  echo "Dry run warning: working tree is not clean." >&2
fi

CURRENT_MARKETING_VERSION="$(grep -m1 'MARKETING_VERSION = ' "$PROJECT_PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([^;]+);/\1/')"
CURRENT_BUILD_VERSION="$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PROJECT_PBXPROJ" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([^;]+);/\1/')"

if [[ -z "$BUILD_VERSION" ]]; then
  if ! [[ "$CURRENT_BUILD_VERSION" =~ ^[0-9]+$ ]]; then
    echo "Current build version is not numeric: $CURRENT_BUILD_VERSION" >&2
    echo "Pass --build-version explicitly." >&2
    exit 1
  fi
  BUILD_VERSION="$((CURRENT_BUILD_VERSION + 1))"
fi

if ! [[ "$BUILD_VERSION" =~ ^[0-9]+$ ]]; then
  echo "--build-version must be numeric." >&2
  exit 1
fi

if [[ -z "$RELEASE_TAG" ]]; then
  RELEASE_TAG="v$MARKETING_VERSION"
fi

if git rev-parse "$RELEASE_TAG" >/dev/null 2>&1; then
  if [[ "$DRY_RUN" != "true" ]]; then
    echo "Tag already exists locally: $RELEASE_TAG" >&2
    exit 1
  fi
  echo "Dry run warning: local tag already exists: $RELEASE_TAG" >&2
fi

REMOTE_URL="$(git remote get-url "$GIT_REMOTE")"
if [[ -z "$DOWNLOAD_URL_PREFIX" ]]; then
  REPO_SLUG=""
  if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
    REPO_SLUG="${BASH_REMATCH[1]}"
  fi

  if [[ -z "$REPO_SLUG" ]]; then
    echo "Could not derive GitHub repo from remote '$GIT_REMOTE': $REMOTE_URL" >&2
    echo "Pass --download-url-prefix explicitly." >&2
    exit 1
  fi

  DOWNLOAD_URL_PREFIX="https://github.com/$REPO_SLUG/releases/download/$RELEASE_TAG"
fi

if [[ "$YES_MODE" != "true" ]]; then
  cat <<EOF
About to run release workflow:

- Current version: $CURRENT_MARKETING_VERSION ($CURRENT_BUILD_VERSION)
- New version:     $MARKETING_VERSION ($BUILD_VERSION)
- Tag:             $RELEASE_TAG
- Download prefix: $DOWNLOAD_URL_PREFIX
- Keychain profile:$KEYCHAIN_PROFILE
- Git remote:      $GIT_REMOTE

Continue? [y/N]
EOF
  read -r confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

if [[ "$DRY_RUN" == "true" ]]; then
  cat <<EOF

Dry run complete. No changes were made.

Computed release values:
- Branch:             $CURRENT_BRANCH
- Current version:    $CURRENT_MARKETING_VERSION ($CURRENT_BUILD_VERSION)
- New version:        $MARKETING_VERSION ($BUILD_VERSION)
- Release tag:        $RELEASE_TAG
- Download prefix:    $DOWNLOAD_URL_PREFIX
- Output dir:         $OUTPUT_DIR
- Updates dir:        $UPDATES_DIR
- Pages target:       $GIT_REMOTE/$PAGES_BRANCH ($PAGES_SITE_SUBDIR)

Planned commands:
1) git add "$PROJECT_PBXPROJ"
2) git commit -m "Release $MARKETING_VERSION ($BUILD_VERSION)"
3) git tag -a "$RELEASE_TAG" -m "Release $RELEASE_TAG"
4) scripts/build_notarize_release.sh --keychain-profile "$KEYCHAIN_PROFILE" --team-id "$TEAM_ID" --output-dir "$OUTPUT_DIR"
5) scripts/release_sparkle.sh --app-path "$OUTPUT_DIR/export/FracTile.app" --updates-dir "$UPDATES_DIR" --download-url-prefix "$DOWNLOAD_URL_PREFIX" --maximum-deltas "$MAXIMUM_DELTAS"
6) scripts/publish_appcast_pages.sh --source-dir "$UPDATES_DIR" --branch "$PAGES_BRANCH" --remote "$GIT_REMOTE" --site-subdir "$PAGES_SITE_SUBDIR"

Notes:
- Push steps are currently $( [[ "$SKIP_GIT_PUSH" == "true" ]] && echo "disabled" || echo "enabled" ).
- Pages publish is currently $( [[ "$SKIP_PAGES_PUBLISH" == "true" ]] && echo "disabled" || echo "enabled" ).
EOF
  exit 0
fi

python3 - "$PROJECT_PBXPROJ" "$MARKETING_VERSION" "$BUILD_VERSION" <<'PY'
import pathlib
import re
import sys

pbxproj = pathlib.Path(sys.argv[1])
marketing = sys.argv[2]
build = sys.argv[3]
content = pbxproj.read_text(encoding="utf-8")

updated = re.sub(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {marketing};", content)
updated = re.sub(r"CURRENT_PROJECT_VERSION = [^;]+;", f"CURRENT_PROJECT_VERSION = {build};", updated)

if updated == content:
    raise SystemExit("No version fields were changed in project.pbxproj")

pbxproj.write_text(updated, encoding="utf-8")
PY

git add "$PROJECT_PBXPROJ"

git commit -m "Release $MARKETING_VERSION ($BUILD_VERSION)"
git tag -a "$RELEASE_TAG" -m "Release $RELEASE_TAG"

if [[ "$SKIP_GIT_PUSH" != "true" ]]; then
  git push "$GIT_REMOTE" main
  git push "$GIT_REMOTE" "$RELEASE_TAG"
else
  echo "Skipping git push (--skip-git-push)."
fi

scripts/build_notarize_release.sh \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --team-id "$TEAM_ID" \
  --output-dir "$OUTPUT_DIR"

RELEASE_SPARKLE_ARGS=(
  --app-path "$OUTPUT_DIR/export/FracTile.app"
  --updates-dir "$UPDATES_DIR"
  --download-url-prefix "$DOWNLOAD_URL_PREFIX"
  --maximum-deltas "$MAXIMUM_DELTAS"
)

if [[ -n "$RELEASE_NOTES_PATH" ]]; then
  RELEASE_SPARKLE_ARGS+=(--release-notes "$RELEASE_NOTES_PATH")
fi

if [[ -n "$SPARKLE_BIN_DIR" ]]; then
  RELEASE_SPARKLE_ARGS+=(--sparkle-bin-dir "$SPARKLE_BIN_DIR")
fi

scripts/release_sparkle.sh "${RELEASE_SPARKLE_ARGS[@]}"

ARCHIVE_GLOB="$UPDATES_DIR/FracTile-${MARKETING_VERSION}-${BUILD_VERSION}.zip"
ARCHIVE_PATH="$ARCHIVE_GLOB"
if [[ ! -f "$ARCHIVE_PATH" ]]; then
  ARCHIVE_PATH="$(ls -t "$UPDATES_DIR"/*.zip 2>/dev/null | head -n 1 || true)"
fi

if [[ "$SKIP_PAGES_PUBLISH" == "true" ]]; then
  cat <<EOF

Skipped Pages publish (--skip-pages-publish).
When ready:
1) Upload release asset to GitHub: ${ARCHIVE_PATH:-<zip-file>}
2) Run scripts/publish_appcast_pages.sh --source-dir "$UPDATES_DIR" --branch "$PAGES_BRANCH" --remote "$GIT_REMOTE" --site-subdir "$PAGES_SITE_SUBDIR"
EOF
  exit 0
fi

if [[ "$YES_MODE" != "true" ]]; then
  cat <<EOF

Upload the generated release asset to GitHub before appcast publish:
- Tag:   $RELEASE_TAG
- Asset: ${ARCHIVE_PATH:-<zip-file-in-$UPDATES_DIR>}

Press Enter to publish appcast to Pages, or Ctrl-C to stop.
EOF
  read -r _unused
fi

scripts/publish_appcast_pages.sh \
  --source-dir "$UPDATES_DIR" \
  --branch "$PAGES_BRANCH" \
  --remote "$GIT_REMOTE" \
  --site-subdir "$PAGES_SITE_SUBDIR"

cat <<EOF

Release workflow complete.

Published:
- Git tag: $RELEASE_TAG
- Archive: ${ARCHIVE_PATH:-<zip-file-in-$UPDATES_DIR>}
- Appcast: $UPDATES_DIR/appcast.xml

Verify:
- GitHub release has the archive referenced by appcast.
- SUFeedURL serves the latest appcast.
- In-app Check for Updates sees the new version.
EOF
