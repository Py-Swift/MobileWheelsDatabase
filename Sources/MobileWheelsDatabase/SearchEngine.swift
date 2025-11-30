import Foundation

/// Simple search engine for package search
/// Actual database operations are handled by sql.js on the JavaScript side
public class SearchEngine {
    private let db: DatabaseManager
    
    public init(db: DatabaseManager) {
        self.db = db
    }
    
    /// Search for packages matching query
    public func search(query: String, limit: Int = 500) -> SearchResult {
        let startTime = Date()
        
        guard query.count >= 2 else {
            return SearchResult(packages: [], searchTime: 0, totalFound: 0)
        }
        
        // Simple in-memory search
        let results = db.searchPackages(query: query, limit: limit)
        
        // Convert to PackageInfo format if needed
        let packages = results.map { package in
            PackageInfo(
                name: package.name,
                hashId: package.hashId,
                downloads: package.downloads,
                iosSupport: package.iosSupport == true ? .success : .unknown,
                androidSupport: package.androidSupport == true ? .success : .unknown,
                source: .pypi,
                category: .purePython,
                iosVersion: nil,
                androidVersion: nil,
                latestVersion: nil
            )
        }
        
        let searchTime = Date().timeIntervalSince(startTime)
        return SearchResult(packages: packages, searchTime: searchTime, totalFound: results.count)
    }
}
