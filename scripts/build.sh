#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:---build}"
case "$MODE" in --build|--restart|--package) ;; *) echo "Usage: build.sh [--build|--restart|--package]" >&2; exit 1 ;; esac
if [ "$MODE" = "--package" ]; then
    APP="$PWD/.build/package/Mouse Click Sound.app"
    IDENTITY="-"
else
    APP="$PWD/dist/Mouse Click Sound.app"
    IDENTITY="${CODESIGN_IDENTITY:-}"
    if [ -z "$IDENTITY" ]; then
        if security find-identity -v -p codesigning 2>/dev/null | grep -Fq '"Mouse Click Sound Local Development"'; then
            IDENTITY="Mouse Click Sound Local Development"
        else
            IDENTITY="-"
        fi
    fi
fi
if [ "$IDENTITY" != "-" ] && ! security find-identity -v -p codesigning | grep -Fq "\"$IDENTITY\""; then
    echo "Signing identity not found: $IDENTITY" >&2
    exit 1
fi
if [ "$MODE" = "--build" ]; then
    swift scripts/app-control.swift check "$APP"
fi
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
if [ "$MODE" = "--restart" ]; then
    swift scripts/app-control.swift stop "$APP"
fi
if [ "$MODE" = "--package" ]; then
    rm -rf "$APP"
fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/MouseClickSound" "$APP/Contents/MacOS/MouseClickSound"
cp Info.plist "$APP/Contents/Info.plist"
cp Sources/MouseClickSound/Resources/* "$APP/Contents/Resources/"
codesign --force --sign "$IDENTITY" --identifier codes.aleksa.mouse-click-sound "$APP"
codesign --verify --strict "$APP"
echo "Built: $APP"
if [ "$MODE" = "--restart" ]; then
    open "$APP"
fi
if [ "$MODE" = "--package" ]; then
    STAGING="$PWD/.build/package/dmg"
    DMG="$PWD/dist/Mouse-Click-Sound-macOS.dmg"
    ZIP="$PWD/dist/Mouse-Click-Sound-macOS.zip"
    mkdir -p "$PWD/dist"
    rm -rf "$STAGING"
    mkdir -p "$STAGING"
    ditto "$APP" "$STAGING/Mouse Click Sound.app"
    ln -s /Applications "$STAGING/Applications"
    rm -f "$DMG"
    hdiutil create -volname "Mouse Click Sound" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
    rm -rf "$STAGING"
    rm -f "$ZIP"
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
    echo "Packaged ad-hoc-signed DMG: $DMG"
    echo "Packaged ad-hoc-signed ZIP: $ZIP"
fi
