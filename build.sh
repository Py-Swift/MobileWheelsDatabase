#!/bin/bash
# Build script for MobileWheelsDatabase
# Builds Swift WASM using Swift 6.2.1 official WASM support

set -e

# Use Swift 6.2.1 WASM toolchain
echo "🔨 Building Swift WASM..."
swift build --swift-sdk swift-6.2.1-RELEASE_wasm -c release \
  --product MobileWheelsDatabaseWasm \
  -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor

echo "📦 Copying WASM binary..."
cp .build/wasm32-unknown-wasip1/release/MobileWheelsDatabaseWasm.wasm ./

SIZE=$(ls -lh MobileWheelsDatabaseWasm.wasm | awk '{print $5}')
echo "✅ WASM built: $SIZE"

# Copy to docs/assets directory (used by mkdocs)
if [ -d "../docs" ]; then
    echo "📋 Copying to docs/assets/..."
    mkdir -p ../docs/assets
    cp MobileWheelsDatabaseWasm.wasm ../docs/assets/MobileWheelsDatabase.wasm
    echo "✅ Files copied to docs/assets/"
fi

echo ""
echo "🎉 Build complete!"
echo "To test locally: python3 -m http.server 8000"
