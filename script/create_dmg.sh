#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BondedBrightness"
DMG_NAME="${DMG_NAME:-BondedBrightness.dmg}"
TEMP_DMG_DIR="temp_dmg"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure we are in the root directory
cd "$ROOT_DIR"

# Build the app bundle first to ensure it's fresh
APP_BUNDLE="$("$ROOT_DIR/script/package_app.sh")"

# Clean up previous attempts
rm -rf "$TEMP_DMG_DIR"
rm -f "$DMG_NAME"

# Create temp directory for DMG contents
mkdir -p "$TEMP_DMG_DIR"

# Copy the app
cp -R "$APP_BUNDLE" "$TEMP_DMG_DIR/"

# Create a symlink to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf "$TEMP_DMG_DIR"

echo "DMG created at $DMG_NAME"
