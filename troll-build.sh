#!/bin/bash

# Configuration
PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin"
export PATH

LOG_FILE="/tmp/troll-build.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "--- $(date) ---"
echo "🔍 Detecting active Xcode project..."

IPHONE_HOST="iphone.local"
IPHONE_USER="mobile"
IPHONE_DEST_DIR="/var/mobile/Documents"

# Detect current project path from Xcode
XCODE_PROJ_PATH=$(osascript -e 'tell application "Xcode" to get path of active workspace document' 2>/dev/null)

if [ -z "$XCODE_PROJ_PATH" ]; then
    echo "❌ Error: Could not detect active Xcode project path. Is Xcode open?"
    exit 1
fi

echo "📂 Project path detected: $XCODE_PROJ_PATH"

# Derive names and directory
PROJECT_DIR=$(dirname "$XCODE_PROJ_PATH")
PROJECT_FILE=$(basename "$XCODE_PROJ_PATH")
PROJECT_NAME="${PROJECT_FILE%.*}"
SCHEME_NAME="$PROJECT_NAME"
APP_NAME="$PROJECT_NAME"

# Change directory to project root
cd "$PROJECT_DIR" || { echo "❌ Error: Could not change to directory $PROJECT_DIR"; exit 1; }

echo "🚀 Starting build for $PROJECT_NAME..."

# 1. Clean and build for iOS device
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$SCHEME_NAME" \
           -configuration Release \
           -destination "generic/platform=iOS" \
           -derivedDataPath ./build \
           clean build \
           CODE_SIGN_IDENTITY="-" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "📦 Packaging IPA..."

# 2. Create the IPA package
rm -rf Payload "$APP_NAME.ipa"
mkdir Payload
cp -r "build/Build/Products/Release-iphoneos/$APP_NAME.app" Payload/
zip -r "$APP_NAME.ipa" Payload
rm -rf Payload

if [ $? -ne 0 ]; then
    echo "❌ Packaging failed."
    exit 1
fi

echo "📲 Transferring $APP_NAME.ipa to iPhone..."

# 3. Transfer to iPhone
scp "$APP_NAME.ipa" "$IPHONE_USER@$IPHONE_HOST:$IPHONE_DEST_DIR/"

if [ $? -ne 0 ]; then
    echo "❌ Transfer failed. Check SSH connection to $IPHONE_USER@$IPHONE_HOST."
    exit 1
fi

echo "⚡️ Triggering TrollStore installation..."

# 4. Trigger installation
ssh "$IPHONE_USER@$IPHONE_HOST" "uiopen \"apple-magnifier://install?url=file://$IPHONE_DEST_DIR/$APP_NAME.ipa\""

if [ $? -ne 0 ]; then
    echo "❌ Installation trigger failed."
    exit 1
fi

echo "✅ Success! Check your iPhone for the TrollStore prompt."
echo "📦 IPA saved at: $PROJECT_DIR/$APP_NAME.ipa"
