# MobileWheelsDatabase

Swift WebAssembly-based search engine for the Mobile Wheels package database.

## Overview

This project provides a Swift-based search interface that runs in the browser via WebAssembly. It uses your existing SQLite database files and Swift enums for type-safe package searching.

## Features

- ✅ **Native Swift code** with your existing enums (`PackageSourceIndex`, `SupportStatus`, etc.)
- ✅ **Type-safe database operations** 
- ✅ **Reuses sql.js** for SQLite operations (proven and optimized)
- ✅ **JavaScript interop** via JavaScriptKit
- ✅ **Same enum values** as your database generator

## Prerequisites

1. **SwiftWasm Toolchain**: Download from [swiftwasm/swift releases](https://github.com/swiftwasm/swift/releases)
2. **carton** (build tool): `brew install swiftwasm/tap/carton`

## Building

### Development Build
```bash
cd MobileWheelsDatabase
carton dev
```

### Production Build
```bash
carton bundle --release
```

This creates optimized WASM files in `.build/debug/MobileWheelsDatabase.wasm` (or `.build/release/` for release builds).

## Usage in Browser

### 1. Include the WASM bundle

```html
<!-- Load sql.js first -->
<script src="https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/sql-wasm.js"></script>

<!-- Load Swift WASM runtime -->
<script type="module">
  import { SwiftRuntime } from './carton_bundle.js';
  
  // Initialize Swift runtime
  const swift = await SwiftRuntime.create();
  
  // Wait for Swift to load
  await new Promise(resolve => setTimeout(resolve, 100));
  
  // Initialize sql.js
  const SQL = await initSqlJs({
    locateFile: file => `https://cdn.jsdelivr.net/npm/sql.js@1.8.0/dist/${file}`
  });
  
  // Initialize Swift search engine with sql.js
  window.SwiftSearch.initialize(SQL);
  
  // Load index database
  const indexBuffer = await fetch('../mobile-wheels-sql/index.sqlite')
    .then(r => r.arrayBuffer());
  window.SwiftSearch.loadIndex(indexBuffer);
  
  // Load data chunks as needed
  async function loadChunk(num) {
    const buffer = await fetch(`../mobile-wheels-sql/data-${num}.sqlite`)
      .then(r => r.arrayBuffer());
    window.SwiftSearch.loadChunk(num, buffer);
  }
  
  // Search!
  const result = window.SwiftSearch.search('numpy', {
    ios: true,
    android: true,
    purePython: true,
    binary: true
  });
  
  console.log('Found:', result.packages.length);
  console.log('Search time:', result.searchTime, 'seconds');
  console.log('First result:', result.packages[0]);
</script>
```

### 2. API Reference

**`SwiftSearch.initialize(sqlJS)`**
- Initializes the search engine with sql.js instance
- Call once on page load

**`SwiftSearch.loadIndex(buffer)`**
- Loads the main index database
- `buffer`: ArrayBuffer from index.sqlite

**`SwiftSearch.loadChunk(chunkNum, buffer)`**
- Loads a data chunk
- `chunkNum`: Chunk number (1-15)
- `buffer`: ArrayBuffer from data-N.sqlite

**`SwiftSearch.search(query, filters)`**
- Performs package search
- `query`: Search string
- `filters`: `{ ios, android, purePython, binary }` (all boolean)
- Returns: `{ packages: [...], searchTime: number, totalFound: number }`

## Architecture

```
┌─────────────────────────────────────┐
│     Browser JavaScript              │
│  (calls SwiftSearch API)            │
└──────────────┬──────────────────────┘
               │
               ├─> SwiftSearch.search(query)
               │
┌──────────────▼──────────────────────┐
│    Swift WASM (main.swift)          │
│  - JavaScript API exposure          │
│  - Type conversion                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   SearchEngine.swift                │
│  - Search logic                     │
│  - Filter application               │
│  - Result parsing                   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   DatabaseBridge.swift              │
│  - Calls sql.js via JavaScriptKit   │
│  - Query execution                  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   sql.js (JavaScript)               │
│  - SQLite execution                 │
└─────────────────────────────────────┘
```

## Project Structure

```
MobileWheelsDatabase/
├── Package.swift           # Swift package manifest
├── Sources/
│   └── MobileWheelsDatabase/
│       ├── main.swift      # JavaScript API & entry point
│       ├── Enums.swift     # Your database enums
│       ├── Models.swift    # PackageInfo, SearchResult, etc.
│       ├── DatabaseBridge.swift  # sql.js bridge
│       └── SearchEngine.swift    # Search logic
└── Tests/
```

## Development Tips

### Testing Locally
```bash
# Start dev server
carton dev

# Opens browser at http://127.0.0.1:8080
# Changes auto-reload
```

### Debugging
```swift
let console = JSObject.global.console
_ = console.log?("Debug message")
_ = console.error?("Error message")
```

### Performance
- Initial WASM load: ~500KB-1MB (gzipped)
- Search performance: ~same as JavaScript (SQL query dominates)
- Type safety: Compile-time checks for all enums

## Next Steps

1. **Build the project**:
   ```bash
   cd MobileWheelsDatabase
   swift package resolve  # Download dependencies
   carton bundle          # Build WASM
   ```

2. **Integrate into docs**: Copy build output to `docs/` and update `package-search.md`

3. **Deploy**: The WASM files can be served as static assets

## Benefits Over Pure JavaScript

- ✅ **Type safety**: Enum mismatches caught at compile time
- ✅ **Code reuse**: Share enums with database generator
- ✅ **Better tooling**: Xcode autocomplete, refactoring
- ✅ **Future-proof**: Easy to add complex Swift logic later
- ✅ **Maintainability**: One source of truth for data structures

## Known Limitations

- Bundle size: ~500KB-1MB (vs ~100KB for pure JS)
- First-time load: Slightly slower due to WASM compilation
- Requires modern browser with WASM support
