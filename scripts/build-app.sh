#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Function Keys"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/release/FunctionKeys"
INFO_PLIST="$APP_DIR/Contents/Info.plist"
APP_VERSION="${APP_VERSION:-}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-1}"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/AppBundle/Info.plist" "$INFO_PLIST"
cp "$ROOT_DIR/AppBundle/AppIcon.icns" "$APP_DIR/Contents/Resources/"

if [[ -n "$APP_VERSION" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$INFO_PLIST"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD_NUMBER" "$INFO_PLIST"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/FunctionKeys"
chmod +x "$APP_DIR/Contents/MacOS/FunctionKeys"

if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
    codesign --force --sign - "$APP_DIR"
else
    codesign --force --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_DIR"
fi

echo "$APP_DIR"
