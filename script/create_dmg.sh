#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BondedBrightness"
DMG_NAME="BondedBrightness.dmg"
DIST_DIR="dist"
TEMP_DMG_DIR="temp_dmg"

# Ensure we are in the root directory
cd "$(dirname "$0")/.."

# Build the app first to ensure it's fresh
./script/build_and_run.sh --verify

# Clean up previous attempts
rm -rf "$TEMP_DMG_DIR"
rm -f "$DMG_NAME"

# Create temp directory for DMG contents
mkdir -p "$TEMP_DMG_DIR"

# Copy the app
cp -R "$DIST_DIR/$APP_NAME.app" "$TEMP_DMG_DIR/"

# Create a symlink to Applications
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create the DMG
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf "$TEMP_DMG_DIR"

echo "DMG created at $DMG_NAME"
