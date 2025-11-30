# Swift WASM SQLite Package Database

Welcome to the Swift WASM SQLite test site!

This site demonstrates using **Swift compiled to WebAssembly** with **native SQLite** to power a fast package search through 714,850+ Python packages.

## Features

- 🚀 **Swift WASM Backend** - Search engine compiled from Swift to WebAssembly
- 💾 **Native SQLite** - Using custom CSQLite module bundled in WASM
- 🔍 **Real-time Search** - Fast searches through hundreds of thousands of packages
- 📱 **Mobile Support Info** - Check iOS and Android compatibility for Python packages

## Quick Start

Head over to the [Package Search](package-search.md) page to try it out!

## Technical Details

This project uses:

- **Swift Package Manager** with custom CSQLite module
- **SQLite.swift** library modified to use CSQLite
- **WASM compilation** for browser execution
- **Zero external dependencies** in the browser (no sql.js needed)

All database operations run entirely in Swift/WASM with native SQLite performance.
