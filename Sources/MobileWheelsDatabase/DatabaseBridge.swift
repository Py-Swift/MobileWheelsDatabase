// Pure Swift In-Memory Database Implementation for WASM
// This provides a simplified database for package search without C dependencies

import Foundation

// MARK: - Database Error Handling

public enum DatabaseError: Error, CustomStringConvertible {
    case notFound(message: String)
    case invalidOperation(message: String)
    case constraint(message: String)
    
    public var description: String {
        switch self {
        case .notFound(let message): return "Not found: \(message)"
        case .invalidOperation(let message): return "Invalid operation: \(message)"
        case .constraint(let message): return "Constraint violation: \(message)"
        }
    }
}

// MARK: - Package Model

public struct Package: Codable {
    public let name: String
    public let hashId: String
    public let chunkFile: Int
    public let downloads: Int?
    public let androidSupport: Bool?
    public let iosSupport: Bool?
    
    public init(name: String, hashId: String, chunkFile: Int, downloads: Int? = nil, 
                androidSupport: Bool? = nil, iosSupport: Bool? = nil) {
        self.name = name
        self.hashId = hashId
        self.chunkFile = chunkFile
        self.downloads = downloads
        self.androidSupport = androidSupport
        self.iosSupport = iosSupport
    }
}

// MARK: - Database Manager

/// Simple in-memory database manager for package search
/// Uses sql.js on the JavaScript side for actual database operations
public class DatabaseManager {
    private var packages: [String: Package] = [:]
    
    public init() {}
    
    public func addPackage(_ package: Package) {
        packages[package.name] = package
    }
    
    public func searchPackages(query: String, limit: Int = 1000) -> [Package] {
        let lowercasedQuery = query.lowercased()
        return packages.values
            .filter { $0.name.lowercased().contains(lowercasedQuery) }
            .prefix(limit)
            .sorted { $0.name < $1.name }
            .map { $0 }
    }
    
    public func getTotalPackages() -> Int {
        return packages.count
    }
}
