import Foundation

/// Package information from the database (matching RealmModels.PackageResult structure)
public struct PackageInfo: Codable {
    public let name: String
    public let hashId: String
    public let downloads: Int?
    public let iosSupport: PlatformSupportCategory
    public let androidSupport: PlatformSupportCategory
    public let source: PackageSourceIndex
    public let category: PackageCategoryType
    public let iosVersion: String?
    public let androidVersion: String?
    public let latestVersion: String?
    
    public init(
        name: String,
        hashId: String,
        downloads: Int? = nil,
        iosSupport: PlatformSupportCategory,
        androidSupport: PlatformSupportCategory,
        source: PackageSourceIndex,
        category: PackageCategoryType,
        iosVersion: String? = nil,
        androidVersion: String? = nil,
        latestVersion: String? = nil
    ) {
        self.name = name
        self.hashId = hashId
        self.downloads = downloads
        self.iosSupport = iosSupport
        self.androidSupport = androidSupport
        self.source = source
        self.category = category
        self.iosVersion = iosVersion
        self.androidVersion = androidVersion
        self.latestVersion = latestVersion
    }
    
    /// Get category display name based on source
    public var categoryDisplayName: String {
        category.categoryDisplayName(source: source)
    }
    
    /// Check if package is supported on iOS
    public var isIOSSupported: Bool {
        iosSupport.isSupported
    }
    
    /// Check if package is supported on Android
    public var isAndroidSupported: Bool {
        androidSupport.isSupported
    }
    
    /// Check if package is pure Python
    public var isPurePython: Bool {
        iosSupport == .purePython || androidSupport == .purePython || category == .purePython
    }
}

/// Search filters
public struct SearchFilters {
    public var ios: Bool
    public var android: Bool
    public var purePython: Bool
    public var binary: Bool
    
    public init(ios: Bool = true, android: Bool = true, purePython: Bool = true, binary: Bool = true) {
        self.ios = ios
        self.android = android
        self.purePython = purePython
        self.binary = binary
    }
    
    /// Check if package matches filters
    public func matches(_ package: PackageInfo) -> Bool {
        let hasIOS = package.isIOSSupported
        let hasAndroid = package.isAndroidSupported
        let isPure = package.isPurePython
        let isBinary = package.category == .supported && !isPure
        
        if !ios && hasIOS && !isPure { return false }
        if !android && hasAndroid && !isPure { return false }
        if !purePython && isPure { return false }
        if !binary && isBinary && !isPure { return false }
        
        return true
    }
}

/// Search result with metadata
public struct SearchResult {
    public let packages: [PackageInfo]
    public let searchTime: Double
    public let totalFound: Int
    
    public init(packages: [PackageInfo], searchTime: Double, totalFound: Int) {
        self.packages = packages
        self.searchTime = searchTime
        self.totalFound = totalFound
    }
}
