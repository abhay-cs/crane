#!/usr/bin/env bash
#
# Builds a distributable crane.dmg without an Apple Developer account.
#
# The app is ad-hoc signed (required on Apple Silicon), not notarized, so
# Gatekeeper warns on first open — install steps for users are in README.md.
# Upload the DMG to a GitHub Release:
#
#   gh release create v<version> dist/crane-<version>.dmg
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="$ROOT/build/Release-dist"
APP="$DERIVED/Build/Products/Release/crane.app"
DIST="$ROOT/dist"

echo "==> Building crane (Release, ad-hoc signed)..."
xcodebuild \
  -project "$ROOT/crane.xcodeproj" \
  -scheme crane \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  CODE_SIGN_ENTITLEMENTS="$ROOT/scripts/dist.entitlements" \
  OTHER_CODE_SIGN_FLAGS="--timestamp=none" \
  build >/dev/null

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG="$DIST/crane-$VERSION.dmg"

echo "==> Verifying signature..."
codesign --verify --strict "$APP"
IDENTITY=$(codesign -dv "$APP" 2>&1 | grep '^Signature' || true)
echo "    $IDENTITY (ad-hoc: no Apple Developer account)"
ENTITLEMENTS=$(codesign -d --entitlements - "$APP" 2>/dev/null)
if echo "$ENTITLEMENTS" | grep -q get-task-allow; then
  echo "FAIL: distribution build must not contain get-task-allow" >&2
  exit 1
fi
if ! echo "$ENTITLEMENTS" | grep -q app-sandbox; then
  echo "FAIL: distribution build lost the App Sandbox entitlement" >&2
  exit 1
fi

echo "==> Creating DMG..."
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
mkdir -p "$DIST"
rm -f "$DMG"
hdiutil create -volname "crane $VERSION" -srcfolder "$STAGING" -format UDZO -quiet "$DMG"

echo "==> Done."
ls -lh "$DMG" | awk '{print "    " $9 " (" $5 ")"}'
shasum -a 256 "$DMG" | awk '{print "    sha256: " $1}'
