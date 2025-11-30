import Foundation

/// Package source index matching RealmModels.PackageSourceIndex
/// Database stores as INTEGER: 0=PyPI, 1=PySwift, 2=KivySchool
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
    
    public var description: String {
        switch self {
        case .pypi: return "pypi"
        case .pyswift: return "pyswift"
        case .kivyschool: return "kivy-school"
        }
    }
}

/// Platform support status matching RealmModels.PlatformSupportCategory
/// Database stores as INTEGER: 0=unknown, 1=success, 2=purePython, 3=warning
public enum PlatformSupportCategory: Int, Codable {
    case unknown = 0
    case success = 1        // Has binary wheels for the platform
    case purePython = 2     // Pure Python package (works on all platforms)
    case warning = 3        // No binary wheels available
    
    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .success: return "Success"
        case .purePython: return "Pure Python"
        case .warning: return "Warning"
        }
    }
    
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .success: return "success"
        case .purePython: return "pure-python"
        case .warning: return "warning"
        }
    }
    
    public var isSupported: Bool {
        return self == .success || self == .purePython
    }
    
    /// Convert to JavaScript-compatible string for browser display
    public var jsValue: String {
        switch self {
        case .unknown, .warning: return "not_available"
        case .success: return "supported"
        case .purePython: return "pure_python"
        }
    }
}

/// Package category matching RealmModels.PackageCategoryType
/// Database stores as INTEGER: 0=unprocessed, 1=supported, 4=purePython, 5=noMobileSupport
public enum PackageCategoryType: Int, Codable {
    case unprocessed = 0
    case supported = 1       // Has binary wheels for mobile platforms
    case purePython = 4
    case noMobileSupport = 5
    
    public var displayName: String {
        switch self {
        case .unprocessed: return "Unprocessed"
        case .supported: return "Supported"
        case .purePython: return "Pure Python"
        case .noMobileSupport: return "No Mobile Support"
        }
    }
    
    public var description: String {
        switch self {
        case .unprocessed: return "unprocessed"
        case .supported: return "supported"
        case .purePython: return "pure-python"
        case .noMobileSupport: return "no-mobile-support"
        }
    }
    
    public func categoryDisplayName(source: PackageSourceIndex) -> String {
        switch self {
        case .unprocessed:
            return "Unprocessed"
        case .supported:
            // Show source for supported packages
            switch source {
            case .pyswift: return "PySwift Binary"
            case .kivyschool: return "KivySchool Binary"
            case .pypi: return "Official Binary (PyPI)"
            }
        case .purePython:
            return "Pure Python"
        case .noMobileSupport:
            return "No Mobile Support"
        }
    }
}

/// Dependency processing status matching RealmModels.DependenciesStatus
/// Database stores as INTEGER: 0=unprocessed, 1=ios_only, 2=android_only, 3=both_platforms, 4=unsupported
public enum DependenciesStatus: Int, Codable {
    case unprocessed = 0
    case ios_only = 1
    case android_only = 2
    case both_platforms = 3
    case unsupported = 4
    
    public var displayName: String {
        switch self {
        case .unprocessed: return "Unprocessed"
        case .ios_only: return "iOS Only"
        case .android_only: return "Android Only"
        case .both_platforms: return "Both Platforms"
        case .unsupported: return "Unsupported"
        }
    }
    
    public var description: String {
        switch self {
        case .unprocessed: return "unprocessed"
        case .ios_only: return "ios-only"
        case .android_only: return "android-only"
        case .both_platforms: return "both-platforms"
        case .unsupported: return "unsupported"
        }
    }
}
