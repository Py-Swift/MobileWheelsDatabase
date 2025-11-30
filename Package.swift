// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MobileWheelsDatabase",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(
            name: "MobileWheelsDatabase",
            targets: ["MobileWheelsDatabase"]),
        .library(
            name: "SQLite",
            targets: ["SQLite"]),
        .executable(
            name: "MobileWheelsDatabaseWasm",
            targets: ["MobileWheelsDatabaseWasm"]),
    ],
    dependencies: [
        // NOTE: swift-toolchain-sqlite doesn't work with WASM Swift SDK
        // We'll bundle SQLite C sources directly instead
    ],
    targets: [
        .target(
            name: "MobileWheelsDatabase"),
        .target(
            name: "SQLite",
            dependencies: ["CSQLite"],
            exclude: [
                "Info.plist"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .define("SQLITE_SWIFT_SQLCIPHER", .when(platforms: [])) // Disable by default
            ]
        ),
        .target(
            name: "CSQLite",
            path: "Sources/CSQLite",
            publicHeadersPath: "include",
            cSettings: [
                .define("SQLITE_OMIT_LOAD_EXTENSION"),
                .define("SQLITE_THREADSAFE", to: "0")
            ]
        ),
        .executableTarget(
            name: "MobileWheelsDatabaseWasm",
            dependencies: ["CSQLite"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableExperimentalFeature("Extern")
            ]
        ),
        .testTarget(
            name: "SQLiteTests",
            dependencies: ["SQLite"]
        ),
    ]
)