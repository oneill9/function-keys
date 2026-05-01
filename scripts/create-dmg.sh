#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Function Keys"
APP_DIR="${APP_DIR:-$ROOT_DIR/dist/$APP_NAME.app}"
APP_VERSION="${APP_VERSION:-}"
DMG_DIR="$ROOT_DIR/dist"

if [[ ! -d "$APP_DIR" ]]; then
    echo "Missing app bundle: $APP_DIR" >&2
    exit 1
fi

if [[ -z "$APP_VERSION" ]]; then
    APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
fi

DMG_PATH="$DMG_DIR/Function-Keys-$APP_VERSION.dmg"
STAGING_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

mkdir -p "$DMG_DIR"
cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Set volume icon
if [[ -f "$APP_DIR/Contents/Resources/AppIcon.icns" ]]; then
    cp "$APP_DIR/Contents/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
    SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$STAGING_DIR" 2>/dev/null || true
fi

hdiutil create \
    -volname "Function Keys" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "$DMG_PATH"
