#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/publish_appcast_pages.sh \
    [--source-dir <path-to-release-updates>] \
    [--branch <pages-branch>] \
    [--remote <git-remote>] \
    [--site-subdir <subdir-on-pages-branch>] \
    [--message <commit-message>] \
    [--no-push]

Defaults:
  --source-dir   ./release/updates
  --branch       gh-pages
  --remote       origin
  --site-subdir  .

This script publishes Sparkle metadata assets (appcast + notes/deltas) from
release/updates to your Pages branch. It intentionally does NOT publish large
release archives like .zip/.dmg/.pkg, which should remain in GitHub Releases.
EOF
}

SOURCE_DIR="./release/updates"
PAGES_BRANCH="gh-pages"
REMOTE_NAME="origin"
SITE_SUBDIR="."
COMMIT_MESSAGE=""
NO_PUSH="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --branch)
      PAGES_BRANCH="$2"
      shift 2
      ;;
    --remote)
      REMOTE_NAME="$2"
      shift 2
      ;;
    --site-subdir)
      SITE_SUBDIR="$2"
      shift 2
      ;;
    --message)
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --no-push)
      NO_PUSH="true"
      shift 1
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

if [[ ! -f "$SOURCE_DIR/appcast.xml" ]]; then
  echo "Missing $SOURCE_DIR/appcast.xml" >&2
  echo "Run scripts/release_sparkle.sh first." >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SOURCE_DIR_ABS="$(cd "$SOURCE_DIR" && pwd)"

if [[ -z "$COMMIT_MESSAGE" ]]; then
  COMMIT_MESSAGE="Publish Sparkle appcast $(date +%Y-%m-%d\ %H:%M:%S)"
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  git -C "$REPO_ROOT" worktree remove "$TMP_DIR" --force >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if git ls-remote --exit-code --heads "$REMOTE_NAME" "$PAGES_BRANCH" >/dev/null 2>&1; then
  git -C "$REPO_ROOT" fetch "$REMOTE_NAME" "$PAGES_BRANCH" >/dev/null
  git -C "$REPO_ROOT" worktree add -B "$PAGES_BRANCH" "$TMP_DIR" "$REMOTE_NAME/$PAGES_BRANCH" >/dev/null
else
  if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$PAGES_BRANCH"; then
    # Reuse local pages branch when remote branch has not been published yet.
    git -C "$REPO_ROOT" worktree add -B "$PAGES_BRANCH" "$TMP_DIR" "$PAGES_BRANCH" >/dev/null
  else
    git -C "$REPO_ROOT" worktree add --detach "$TMP_DIR" >/dev/null
    git -C "$TMP_DIR" checkout --orphan "$PAGES_BRANCH" >/dev/null
    git -C "$TMP_DIR" rm -rf . >/dev/null 2>&1 || true
  fi
fi

TARGET_DIR="$TMP_DIR"
if [[ "$SITE_SUBDIR" != "." ]]; then
  TARGET_DIR="$TMP_DIR/$SITE_SUBDIR"
  mkdir -p "$TARGET_DIR"
fi

mkdir -p "$TARGET_DIR"

# Clear previously published Sparkle metadata in target path.
rm -f "$TARGET_DIR/appcast.xml"
rm -f "$TARGET_DIR"/*.html "$TARGET_DIR"/*.htm "$TARGET_DIR"/*.md "$TARGET_DIR"/*.txt 2>/dev/null || true
rm -f "$TARGET_DIR"/*.delta "$TARGET_DIR"/*.aar 2>/dev/null || true
rm -rf "$TARGET_DIR/old_updates"

cp "$SOURCE_DIR_ABS/appcast.xml" "$TARGET_DIR/appcast.xml"

for ext in html htm md txt delta aar; do
  for file in "$SOURCE_DIR_ABS"/*."$ext"; do
    [[ -e "$file" ]] || continue
    cp "$file" "$TARGET_DIR/"
  done
done

if [[ -d "$SOURCE_DIR_ABS/old_updates" ]]; then
  cp -R "$SOURCE_DIR_ABS/old_updates" "$TARGET_DIR/old_updates"
fi

git -C "$TMP_DIR" add "$SITE_SUBDIR"

if git -C "$TMP_DIR" diff --cached --quiet; then
  echo "No appcast metadata changes to publish."
  exit 0
fi

git -C "$TMP_DIR" commit -m "$COMMIT_MESSAGE" >/dev/null

if [[ "$NO_PUSH" == "true" ]]; then
  echo "Committed locally but did not push (--no-push)."
  exit 0
fi

git -C "$TMP_DIR" push "$REMOTE_NAME" "$PAGES_BRANCH" >/dev/null

echo "Published Sparkle metadata to $REMOTE_NAME/$PAGES_BRANCH at subdir '$SITE_SUBDIR'."
