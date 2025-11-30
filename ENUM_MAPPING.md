# Enum Mapping Documentation

This document explains how the MobilePlatformSupport Swift library enums map to the SQLite database integer values used by MobileWheelsDatabase.

## Source Code Locations

- **Realm Models (Source of Truth)**: `/Volumes/CodeSSD/GitHub/wiki-source/MobilePlatformSupport-new/Sources/MobileWheelsChecker/RealmModels.swift`
- **Database WASM Engine**: `/Volumes/CodeSSD/GitHub/wiki-source/MobileWheelsDatabase/Sources/MobileWheelsDatabase/Enums.swift`

## Enum Mappings

### PackageSourceIndex

**Realm Model & Database (both use Integer)**:
```swift
enum PackageSourceIndex: Int, PersistableEnum {
    case pypi = 0
    case pyswift = 1
    case kivyschool = 2
}
```

**Display Names**:
- 0 → "PyPI" / "pypi"
- 1 → "PySwift" / "pyswift"
- 2 → "KivySchool" / "kivy-school"

### PlatformSupportCategory

**Realm Model & Database (both use Integer)**:
```swift
enum PlatformSupportCategory: Int, PersistableEnum {
    case unknown = 0
    case success = 1        // Has binary wheels for the platform
    case purePython = 2     // Pure Python package (works on all platforms)
    case warning = 3        // No binary wheels available
}
```

**Display Names**:
- 0 → "Unknown" / "unknown"
- 1 → "Success" / "success"
- 2 → "Pure Python" / "pure-python"
- 3 → "Warning" / "warning"

**JavaScript Output Mapping** (for browser compatibility):
```swift
public var jsValue: String {
    switch self {
    case .unknown, .warning: return "not_available"
    case .success: return "supported"
    case .purePython: return "pure_python"
    }
}
```

### PackageCategoryType

**Realm Model & Database (both use Integer)**:
```swift
enum PackageCategoryType: Int, PersistableEnum {
    case unprocessed = 0
    case supported = 1       // Has binary wheels for mobile platforms
    case purePython = 4
    case noMobileSupport = 5
}
```

**Display Names**:
- 0 → "Unprocessed" / "unprocessed"
- 1 → "Supported" / "supported" (shows source-specific label)
- 4 → "Pure Python" / "pure-python"
- 5 → "No Mobile Support" / "no-mobile-support"

**Source-Specific Display** (for category=1/supported):
- pypi=0 + supported=1 → "Official Binary (PyPI)"
- pyswift=1 + supported=1 → "PySwift Binary"
- kivyschool=2 + supported=1 → "KivySchool Binary"

### DependenciesStatus

**Realm Model & Database (both use Integer)**:
```swift
enum DependenciesStatus: Int, PersistableEnum {
    case unprocessed = 0
    case ios_only = 1         // iOS dependencies ok, Android has issues
    case android_only = 2     // Android dependencies ok, iOS has issues
    case both_platforms = 3   // Both platforms dependencies ok
    case unsupported = 4      // Both platforms have dependency issues
}
```

**Display Names**:
- 0 → "Unprocessed" / "unprocessed"
- 1 → "iOS Only" / "ios-only"
- 2 → "Android Only" / "android-only"
- 3 → "Both Platforms" / "both-platforms"
- 4 → "Unsupported" / "unsupported"

## Database Schema

### package_index table
- `name` TEXT (package name)
- `hash_id` INTEGER (64-bit hash of package name)
- `chunk_file` INTEGER (1-15, which data chunk contains this package)

### package_data table
- `hash_id` INTEGER (64-bit, primary key)
- `downloads` INTEGER (PyPI download count)
- `android_support` INTEGER (PlatformSupportCategory: 0-3)
- `ios_support` INTEGER (PlatformSupportCategory: 0-3)
- `source` INTEGER (PackageSourceIndex: 0-2)
- `category` INTEGER (PackageCategoryType: 0/1/4/5)
- `android_version` TEXT (version string)
- `ios_version` TEXT (version string)
- `latest_version` TEXT (version string)
- `dependency_status` INTEGER (DependenciesStatus: 0-4)
- `dependency_count` INTEGER (number of dependencies)
- `dependencies` BLOB (serialized dependency list)

## Conversion Flow

### 1. Package Analysis (Realm) → SQLite Database

```swift
// RealmModels.PackageResult
name: "numpy"
androidSupport: .success (1)
iosSupport: .success (1)
source: .pyswift (1)
category: .supported (1)
androidVersion: "2.3.5"
iosVersion: "2.3.5"
latestVersion: "2.3.5"
depStatus: .both_platforms (3)

// Exported to SQLite as:
hash_id: -6508293722772635875
downloads: 1000000
android_support: 1
ios_support: 1
source: 1
category: 1
android_version: "2.3.5"
ios_version: "2.3.5"
latest_version: "2.3.5"
dependency_status: 3
```

### 2. SQLite Database → Swift WASM → JavaScript

```swift
// Swift WASM reads from database:
PackageInfo(
    name: "numpy",
    hashId: "-6508293722772635875",
    downloads: 1000000,
    iosSupport: .success,         // 1
    androidSupport: .success,     // 1
    source: .pyswift,             // 1
    category: .supported,         // 1
    iosVersion: "2.3.5",
    androidVersion: "2.3.5",
    latestVersion: "2.3.5"
)

// Converted to JavaScript object:
{
  name: "numpy",
  ios: "supported",              // .success.jsValue
  android: "supported",          // .success.jsValue
  iosVersion: "2.3.5",
  androidVersion: "2.3.5",
  category: "PySwift Binary",    // .supported.categoryDisplayName(source: .pyswift)
  source: "PySwift"              // .pyswift.displayName
}
```

## Why These Specific Values?

### Category Enum Gaps (0, 1, 4, 5)
The gaps exist because category was simplified during migration:
- Originally: 0=unprocessed, 1=bothPlatforms, 2=androidOnly, 3=iosOnly, 4=purePython, 5=noMobileSupport
- Migration v8: merged 1/2/3 into single "supported" (1)
- Current: 0=unprocessed, 1=supported, 4=purePython, 5=noMobileSupport

### Platform Support Values
- `unknown=0`: Package not yet analyzed
- `success=1`: Has compiled binary wheels
- `purePython=2`: Pure Python (no compilation needed)
- `warning=3`: No wheels available (will fail on mobile)

## Type Safety Benefits

Using integer enums provides:

1. **Direct Mapping**: Realm → SQLite → Swift WASM uses same integer values
2. **Compact Storage**: 1 byte per enum vs 10+ bytes for strings
3. **Fast Queries**: Integer comparison vs string matching
4. **Type Safety**: Compiler validates all enum values
5. **No Conversion Errors**: Same enum definitions everywhere

## Synchronization Workflow

When you update package data:

1. **Analyze Packages**: `MobileWheelsChecker` analyzes PyPI packages
2. **Store in Realm**: Save with integer enum values (RealmModels.swift)
3. **Export to SQLite**: Realm data → SQLite databases (same integer values)
4. **Build WASM**: Swift code compiles to WebAssembly
5. **Browser Search**: JavaScript calls Swift WASM → reads SQLite → displays results

All steps use the **exact same integer enum values**, ensuring perfect consistency from analysis to display.
