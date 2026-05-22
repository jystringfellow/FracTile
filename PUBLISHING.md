# Publishing FracTile Updates (Sparkle + GitHub)

This guide documents the release flow for FracTile using:

- GitHub Releases for app archives
- Sparkle for update checks/signature validation
- GitHub Pages for a stable `appcast.xml` URL

## Prerequisites

- Sparkle integrated in the app target
- `SUPublicEDKey` set in `app/FracTile-Info.plist`
- `SUFeedURL` points to your Pages URL (currently `https://jystringfellow.github.io/FracTile/appcast.xml`)
- A built and signed `FracTile.app` release artifact

## One-time setup

Enable GitHub Pages for this repository (recommended from branch `gh-pages`).

## Per-release flow

### 1) Build + notarize the release app

Use the helper script from repo root:

```bash
scripts/build_notarize_release.sh \
  --keychain-profile fractile-notary \
  --team-id 6T7K8KMSN3 \
  --output-dir ./release
```

Notes:

- This creates/exports a Developer ID-signed app and notarizes it.
- Output app path is typically `release/export/FracTile.app`.

### 2) Prepare release metadata and appcast

Use the helper script from repo root:

```bash
scripts/release_sparkle.sh \
  --app-path ./release/export/FracTile.app \
  --updates-dir ./release/updates \
  --download-url-prefix https://github.com/jystringfellow/FracTile/releases/download/v0.0.5 \
  --maximum-deltas 0 \
  --release-notes ./release/notes/v0.0.5.md
```

Notes:

- `--download-url-prefix` should match the GitHub Release tag you are publishing.
- `--maximum-deltas 0` keeps the flow simple by disabling delta artifacts.
- This script outputs:
  - `release/updates/FracTile-<version>-<build>.zip`
  - `release/updates/appcast.xml`
  - optional release-notes sidecar file

### 3) Upload app archive to GitHub Release

Upload the generated zip archive to your tag release (`v0.0.5` in the example).

### 4) Publish appcast to GitHub Pages

```bash
scripts/publish_appcast_pages.sh \
  --source-dir ./release/updates \
  --branch gh-pages \
  --remote origin \
  --site-subdir .
```

This publishes Sparkle metadata assets to Pages branch:

- `appcast.xml`
- release notes (`.md`, `.html`, `.txt`)
- delta metadata files if present (`.delta`, `.aar`, `old_updates/`)

It does not publish large app archives (`.zip`, `.dmg`, `.pkg`).

## Dry run options

To test appcast publication without pushing:

```bash
scripts/publish_appcast_pages.sh --no-push
```

## Verification checklist

- Confirm GitHub Release includes the exact archive filename referenced in `appcast.xml`.
- Confirm your `SUFeedURL` serves the newly published `appcast.xml`.
- Run current app build and trigger `Check for Updates...`.

## Troubleshooting

- If build/export fails, run `xcodebuild archive` manually first to inspect signing issues.
- If notarization fails, inspect details with `xcrun notarytool history --keychain-profile fractile-notary`.
- If Sparkle tools cannot be found, set `SPARKLE_BIN_DIR` or pass `--sparkle-bin-dir` to `scripts/release_sparkle.sh`.
- If appcast generation fails, ensure the app archive is valid and keychain has your Sparkle private key.
- If Pages publish fails, verify write access to the remote and branch settings.
