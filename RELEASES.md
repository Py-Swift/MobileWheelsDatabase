# Release Process

## Creating a New Release

1. **Build the WASM locally** (optional, for testing):
   ```bash
   swift build --swift-sdk swift-6.2.1-RELEASE_wasm -c release --product MobileWheelsDatabaseWasm
   cp .build/wasm32-unknown-wasip1/release/MobileWheelsDatabaseWasm.wasm docs/assets/MobileWheelsDatabase.wasm
   ```

2. **Create and push a version tag**:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

3. **GitHub Actions will automatically**:
   - Build the WASM binary
   - Create a GitHub release
   - Attach the WASM as a release asset

4. **The plugin automatically downloads the WASM** from the latest release when building sites.

## Manual Release (if needed)

If GitHub Actions fails, you can create a release manually:

1. Build WASM locally (see step 1 above)
2. Go to https://github.com/Py-Swift/MobileWheelsDatabase/releases/new
3. Create a new release with tag (e.g., `v0.1.0`)
4. Upload `MobileWheelsDatabase.wasm` as an asset
5. Publish the release

## Plugin Configuration

Users can specify which release to use:

```yaml
plugins:
  - mobilewheelsdb:
      wasm_release: "latest"  # Or specific tag like "v0.1.0"
```

## File Sizes

- WASM binary: ~59 MB
- SQLite databases: ~181 MB (31 files)
- Total plugin size: ~240 MB

The WASM is downloaded from GitHub releases during site build, so it's not included in the pip package.
