#!/bin/bash

# deploy.sh
# Automates building and launching the YouTubePlaylistCreator app

set -e

PROJECT="YouTubePlaylistCreator.xcodeproj"
SCHEME="YouTubePlaylistCreator"

echo "🚀 Starting build for $SCHEME..."

# Build the project
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=macOS" \
    -quiet

echo "✅ Build successful!"

# Find the build products directory and app name
DERIVED_DATA_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep -m 1 " BUILT_PRODUCTS_DIR =" | cut -d "=" -f2 | xargs)
WRAPPER_NAME=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings | grep -m 1 " WRAPPER_NAME =" | cut -d "=" -f2 | xargs)

APP_PATH="$DERIVED_DATA_PATH/$WRAPPER_NAME"

if [ -d "$APP_PATH" ]; then
    echo "🛑 Closing any existing instances of $SCHEME..."
    killall "$SCHEME" 2>/dev/null || true
    
    echo "⚡️ Launching $WRAPPER_NAME..."
    open "$APP_PATH"
else
    echo "❌ Error: Could not find built app at $APP_PATH"
    exit 1
fi
