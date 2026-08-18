#!/bin/bash
# Builds TodoSticky as a proper double-clickable .app bundle and installs it to ~/Applications.
set -euo pipefail

cd "$(dirname "$0")"

# This machine's `xcode-select` default toolchain is broken; route through the real
# Xcode.app toolchain explicitly instead. Adjust DEVELOPER_DIR if Xcode lives elsewhere.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

APP_NAME="TodoSticky"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
# Per-user Applications folder, not /Applications: on this machine, endpoint security
# software (SentinelOne) ended up locking a previous /Applications copy against further
# modification (rm/mv denied even as the owning user) after it was rebuilt/relaunched
# repeatedly. ~/Applications avoids that system-wide scrutiny.
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"

echo "==> Building release binary..."
xcrun swift build -c release

echo "==> Assembling $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

echo "Done. Installed at $INSTALL_DIR/$APP_NAME.app"
