#!/bin/bash
# Packages TodoSticky.app into a shareable .dmg with a drag-to-Applications layout.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="TodoSticky"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
STAGING_DIR="$DIST_DIR/dmg_staging"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "==> $APP_BUNDLE not found, building first..."
    ./build_app.sh
fi

echo "==> Preparing DMG contents..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating $DMG_PATH..."
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "Done: $DMG_PATH"
