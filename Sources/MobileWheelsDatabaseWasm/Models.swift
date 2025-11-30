import Foundation

// MARK: - Enums (match database integer values)

/// Package source repository
public enum PackageSourceIndex: Int, Codable {
    case pypi = 0
    case pyswift = 1
    case kivyschool = 2
    
    public var displayName: String {
        switch self {
        case .pypi: return "PyPI"
        case .pyswift: return "PySwift"
        case .kivyschool: return "KivySchool"
        }
    }
}

/// Platform support status
public enum PlatformSupportCategory: Int, Codable {
    case unknown = 0
    case success = 1        // Has binary wheels
    case purePython = 2     // Pure Python (works everywhere)
    case warning = 3        // No binary wheels
    
    public var jsValue: String {
        switch self {
        case .unknown, .warning: return "not_available"
        case .success: return "supported"
        case .purePython: return "pure_python"
        }
    }
    
    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .success: return "Supported"
        case .purePython: return "Pure Python"
        case .warning: return "Not Available"
        }
    }
}

/// Package category
public enum PackageCategoryType: Int, Codable {
    case unprocessed = 0
    case supported = 1       // Has binary wheels
    case purePython = 4
    case noMobileSupport = 5
    
    public func categoryDisplayName(source: PackageSourceIndex) -> String {
        switch self {
        case .unprocessed: return "Unprocessed"
        case .supported:
            switch source {
            case .pypi: return "Official Binary (PyPI)"
            case .pyswift: return "PySwift Binary"
            case .kivyschool: return "KivySchool Binary"
            }
        case .purePython: return "Pure Python"
        case .noMobileSupport: return "No Mobile Support"
        }
    }
}

/// Dependencies validation status
public enum DependenciesStatus: Int, Codable {
    case unprocessed = 0
    case ios_only = 1         // iOS ok, Android has issues
    case android_only = 2     // Android ok, iOS has issues
    case both_platforms = 3   // Both ok
    case unsupported = 4      // Both have issues
    
    public var displayName: String {
        switch self {
        case .unprocessed: return "Unprocessed"
        case .ios_only: return "iOS Only"
        case .android_only: return "Android Only"
        case .both_platforms: return "Both Platforms"
        case .unsupported: return "Unsupported"
        }
    }
}

// MARK: - Data Models

/// Package metadata from package_data table
public struct PackageData: Codable {
    public let hashId: Int64
    public let downloads: Int
    public let androidSupport: PlatformSupportCategory
    public let iosSupport: PlatformSupportCategory
    public let source: PackageSourceIndex
    public let category: PackageCategoryType
    public let androidVersion: String?
    public let iosVersion: String?
    public let latestVersion: String?
    public let dependencyStatus: DependenciesStatus
    public let dependencyCount: Int
    public let dependencies: [String]?
    
    enum CodingKeys: String, CodingKey {
        case hashId = "hash_id"
        case downloads
        case androidSupport = "android_support"
        case iosSupport = "ios_support"
        case source
        case category
        case androidVersion = "android_version"
        case iosVersion = "ios_version"
        case latestVersion = "latest_version"
        case dependencyStatus = "dependency_status"
        case dependencyCount = "dependency_count"
        case dependencies
    }
}

/// Package index entry from package_index table
public struct PackageIndex: Codable {
    public let name: String
    public let hashId: Int64
    public let chunkFile: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case hashId = "hash_id"
        case chunkFile = "chunk_file"
    }
}

/// Complete package info for search results
public struct PackageSearchResult: Codable {
    public let name: String
    public let hashId: String
    public let downloads: Int
    public let ios: String
    public let android: String
    public let iosVersion: String?
    public let androidVersion: String?
    public let latestVersion: String?
    public let category: String
    public let source: String
    public let dependencyStatus: String
    public let isValid: Bool  // True if all dependencies are satisfied
    
    enum CodingKeys: String, CodingKey {
        case name
        case hashId = "hash_id"
        case downloads
        case ios
        case android
        case iosVersion = "ios_version"
        case androidVersion = "android_version"
        case latestVersion = "latest_version"
        case category
        case source
        case dependencyStatus = "dependency_status"
        case isValid = "is_valid"
    }
    
    public init(index: PackageIndex, data: PackageData, isValid: Bool) {
        self.name = index.name
        self.hashId = String(index.hashId)
        self.downloads = data.downloads
        self.ios = data.iosSupport.jsValue
        self.android = data.androidSupport.jsValue
        self.iosVersion = data.iosVersion
        self.androidVersion = data.androidVersion
        self.latestVersion = data.latestVersion
        self.category = data.category.categoryDisplayName(source: data.source)
        self.source = data.source.displayName
        self.dependencyStatus = data.dependencyStatus.displayName
        self.isValid = isValid
    }
}
