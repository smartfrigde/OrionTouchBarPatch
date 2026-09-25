#!/usr/bin/env bash
# Build a Release .app and wrap it in a drag-to-Applications DMG.
#
# Usage:
#   ./scripts/package-dmg.sh
#   ./scripts/package-dmg.sh --sign "Developer ID Application: Name (TEAMID)"
#   ./scripts/package-dmg.sh --sign "Developer ID Application: Name (TEAMID)" --notarize notarytool-profile
#
# Requires: Xcode, create-dmg (brew install create-dmg)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="OrionTouchBarPatch"
PROJECT="OrionTouchBarPatch.xcodeproj"
APP_PRODUCT="OrionTouchBarPatch.app"
DMG_APP_NAME="Orion Touch Bar.app"
VOLICON_PNG="OrionTouchBarPatch/Assets.xcassets/AppIcon.appiconset/icon_512.png"

SIGN_IDENTITY=""
NOTARY_PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign)
      SIGN_IDENTITY="${2:?--sign requires an identity string}"
      shift 2
      ;;
    --notarize)
      NOTARY_PROFILE="${2:?--notarize requires a notarytool keychain profile name}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "create-dmg not found. Install with: brew install create-dmg" >&2
  exit 1
fi

VERSION="$(grep -m1 'MARKETING_VERSION' "$PROJECT/project.pbxproj" | sed -E 's/.*MARKETING_VERSION = ([^;]+);/\1/' | tr -d ' ')"
VERSION="${VERSION:-1.0}"

DIST="$ROOT/dist"
DERIVED="$DIST/DerivedData"
STAGE="$DIST/dmg-root"
VOLICON_ICNS="$DIST/VolumeIcon.icns"
DMG_PATH="$DIST/OrionTouchBar-${VERSION}.dmg"

echo "==> Building Release $SCHEME (version $VERSION)"
rm -rf "$DERIVED" "$STAGE" "$DMG_PATH" "$VOLICON_ICNS"
mkdir -p "$STAGE"

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Automatic \
  build

APP_SRC="$DERIVED/Build/Products/Release/$APP_PRODUCT"
if [[ ! -d "$APP_SRC" ]]; then
  echo "Build did not produce $APP_SRC" >&2
  exit 1
fi

echo "==> Staging $DMG_APP_NAME"
ditto "$APP_SRC" "$STAGE/$DMG_APP_NAME"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "==> Codesigning app with: $SIGN_IDENTITY"
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "$SIGN_IDENTITY" \
    "$STAGE/$DMG_APP_NAME"
  codesign --verify --deep --strict --verbose=2 "$STAGE/$DMG_APP_NAME"
fi

# create-dmg prefers an .icns volume icon
if [[ -f "$VOLICON_PNG" ]] && command -v sips >/dev/null 2>&1; then
  ICONSET="$DIST/VolumeIcon.iconset"
  rm -rf "$ICONSET"
  mkdir -p "$ICONSET"
  sips -z 16 16     "$VOLICON_PNG" --out "$ICONSET/icon_16x16.png" >/dev/null
  sips -z 32 32     "$VOLICON_PNG" --out "$ICONSET/diana.k@example.org" >/dev/null
  sips -z 32 32     "$VOLICON_PNG" --out "$ICONSET/icon_32x32.png" >/dev/null
  sips -z 64 64     "$VOLICON_PNG" --out "$ICONSET/ivan.p@example.net" >/dev/null
  sips -z 128 128   "$VOLICON_PNG" --out "$ICONSET/icon_128x128.png" >/dev/null
  sips -z 256 256   "$VOLICON_PNG" --out "$ICONSET/wendy.h@example.net" >/dev/null
  sips -z 256 256   "$VOLICON_PNG" --out "$ICONSET/icon_256x256.png" >/dev/null
  sips -z 512 512   "$VOLICON_PNG" --out "$ICONSET/wendy.h@example.net" >/dev/null
  sips -z 512 512   "$VOLICON_PNG" --out "$ICONSET/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$VOLICON_PNG" --out "$ICONSET/walt.e@example.net" >/dev/null
  iconutil -c icns "$ICONSET" -o "$VOLICON_ICNS"
  rm -rf "$ICONSET"
fi

echo "==> Creating DMG"
CREATE_ARGS=(
  --volname "Orion Touch Bar"
  --window-pos 200 120
  --window-size 540 380
  --icon-size 128
  --icon "$DMG_APP_NAME" 140 180
  --hide-extension "$DMG_APP_NAME"
  --app-drop-link 400 180
  --no-internet-enable
)

if [[ -f "$VOLICON_ICNS" ]]; then
  CREATE_ARGS+=(--volicon "$VOLICON_ICNS")
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
  CREATE_ARGS+=(--codesign "$SIGN_IDENTITY")
fi

if [[ -n "$NOTARY_PROFILE" ]]; then
  CREATE_ARGS+=(--notarize "$NOTARY_PROFILE")
fi

# create-dmg refuses to overwrite; ensure gone
rm -f "$DMG_PATH"

create-dmg "${CREATE_ARGS[@]}" "$DMG_PATH" "$STAGE/"

echo
echo "Done: $DMG_PATH"
ls -lh "$DMG_PATH"
