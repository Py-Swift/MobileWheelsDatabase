#!/bin/bash
# Build script for MobileWheelsDatabase
# Builds Swift WASM using Swift 6.2.1 official WASM support

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Use Swift 6.2.1 WASM toolchain
export TOOLCHAINS=swift-wasm-6.2.1-RELEASE

echo "🔨 Building Swift WASM..."
swift build --swift-sdk swift-6.2.1-RELEASE_wasm -c release \
  -Xswiftc -Xclang-linker -Xswiftc -mexec-model=reactor

echo "📦 Copying WASM binary..."
cp .build/release/MobileWheelsDatabaseWasm.wasm ./

SIZE=$(ls -lh MobileWheelsDatabaseWasm.wasm | awk '{print $5}')
echo "✅ WASM built: $SIZE"

# Copy to docs directory
echo "📋 Copying to docs/assets/..."
mkdir -p docs/assets
cp MobileWheelsDatabaseWasm.wasm docs/assets/MobileWheelsDatabase.wasm
echo "✅ Files copied to docs/assets/"

echo ""
echo "🎉 Build complete!"

echo "Running: uv run mkdocs serve"
uv run mkdocs serve -a 0.0.0.0:8000