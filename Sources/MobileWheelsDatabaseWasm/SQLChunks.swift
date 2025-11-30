import Foundation
import CSQLite

/// Result grouping helper
struct PackagesByChunk {
    let packages: [Int: [(name: String, hashId: Int64)]]
    
    init(from indexResults: [IndexResult]) {
        var grouped: [Int: [(name: String, hashId: Int64)]] = [:]
        for result in indexResults {
            if grouped[result.chunkFile] == nil {
                grouped[result.chunkFile] = []
            }
            grouped[result.chunkFile]?.append((name: result.name, hashId: result.hashId))
        }
        self.packages = grouped
    }
    
    var chunkNumbers: [Int] {
        return Array(packages.keys).sorted()
    }
}

/// Manages all SQLite chunk databases
final class SQLChunks {
    static let shared = SQLChunks()
    
    private var chunkDatabases: [Int: SQLChunk] = [:]
    private let chunksPath = "chunks" // Root path for chunk files
    
    private init() {}
    
    /// Subscript access to chunk database handles
    /// Returns the database handle if chunk is loaded, nil otherwise
    subscript(chunkNum: Int) -> OpaquePointer? {
        get {
            return chunkDatabases[chunkNum]?.db
        }
    }
    
    /// Get the SQLChunk object for a given chunk number
    func getChunk(chunkNum: Int) -> SQLChunk? {
        return chunkDatabases[chunkNum]
    }
    
    /// Check if a chunk is loaded
    func isLoaded(chunkNum: Int) -> Bool {
        return chunkDatabases[chunkNum] != nil
    }
    
    /// Load a chunk from JavaScript-provided bytes
    func loadChunk(chunkNum: Int, dbPtr: UnsafeRawPointer, dbSize: Int) -> Bool {
        // If already loaded, return success
        if chunkDatabases[chunkNum] != nil {
            return true
        }
        
        // Use SQLChunk static method to load
        guard let chunk = SQLChunk.load(chunkNum: chunkNum, dbPtr: dbPtr, dbSize: dbSize) else {
            return false
        }
        
        // Store the chunk
        chunkDatabases[chunkNum] = chunk
        return true
    }
    
    /// Clear all loaded chunks
    func clearAll() {
        chunkDatabases.removeAll()
    }
    
    /// Get statistics about loaded chunks
    var loadedCount: Int {
        return chunkDatabases.count
    }
    
    var totalSize: Int {
        return chunkDatabases.values.reduce(0) { $0 + $1.size }
    }
    
    /// Get all loaded chunk numbers
    var loadedChunkNumbers: [Int] {
        return Array(chunkDatabases.keys).sorted()
    }
    
    /// Check which chunks from a list are not loaded
    func getMissingChunks(from needed: Set<Int>) -> [Int] {
        return needed.filter { !isLoaded(chunkNum: $0) }.sorted()
    }
    
    /// Get all chunks as a comma-separated string (for logging)
    func loadedChunksDescription() -> String {
        return loadedChunkNumbers.map { String($0) }.joined(separator: ", ")
    }
    
    /// Query multiple chunks for package data
    /// - Parameter packagesByChunk: Dictionary mapping chunk numbers to arrays of (name, hashId) tuples
    /// - Returns: Dictionary mapping hash IDs to package data
    func queryPackages(packagesByChunk: [Int: [(name: String, hashId: Int64)]]) -> [Int64: ChunkPackageData] {
        var allData: [Int64: ChunkPackageData] = [:]
        
        for (chunkNum, packages) in packagesByChunk {
            guard let chunk = chunkDatabases[chunkNum] else {
                continue
            }
            
            let hashIds = packages.map { $0.hashId }
            let results = chunk.queryPackages(hashIds: hashIds)
            
            for data in results {
                allData[data.hashId] = data
            }
        }
        
        return allData
    }
    
    /// Sort index results by relevance to query
    static func sortByRelevance(results: [IndexResult], query: String) -> [IndexResult] {
        var sorted = results
        sorted.sort { a, b in
            if a.name == query && b.name != query { return true }
            if a.name != query && b.name == query { return false }
            if a.name.hasPrefix(query) && !b.name.hasPrefix(query) { return true }
            if !a.name.hasPrefix(query) && b.name.hasPrefix(query) { return false }
            if a.name.count != b.name.count { return a.name.count < b.name.count }
            return a.name < b.name
        }
        return sorted
    }
    
    /// Build JSON results from index and chunk data
    static func buildSearchResults(
        indexResults: [IndexResult],
        packageData: [Int64: ChunkPackageData]
    ) -> [[String: Any]] {
        var jsonResults: [[String: Any]] = []
        
        for indexRow in indexResults {
            guard let data = packageData[indexRow.hashId] else {
                // Package not found in data chunks
                let result: [String: Any] = [
                    "name": indexRow.name,
                    "hash_id": String(indexRow.hashId),
                    "chunk_file": indexRow.chunkFile,
                    "ios": "unknown",
                    "android": "unknown",
                    "category": "unknown",
                    "source": "unknown",
                    "downloads": 0
                ]
                jsonResults.append(result)
                continue
            }
            
            let iosSupportStr = PlatformSupportCategory(rawValue: data.iosSupport)?.jsValue ?? "not_available"
            let androidSupportStr = PlatformSupportCategory(rawValue: data.androidSupport)?.jsValue ?? "not_available"
            let sourceObj = PackageSourceIndex(rawValue: data.source) ?? .pypi
            let categoryObj = PackageCategoryType(rawValue: data.category) ?? .unprocessed
            
            var result: [String: Any] = [
                "name": indexRow.name,
                "hash_id": String(indexRow.hashId),
                "downloads": data.downloads,
                "ios": iosSupportStr,
                "android": androidSupportStr,
                "category": categoryObj.categoryDisplayName(source: sourceObj),
                "source": sourceObj.displayName
            ]
            
            if let ver = data.iosVersion { result["ios_version"] = ver }
            if let ver = data.androidVersion { result["android_version"] = ver }
            if let ver = data.latestVersion { result["latest_version"] = ver }
            
            jsonResults.append(result)
        }
        
        return jsonResults
    }
    
    /// Build JSON results for batch lookup (slightly different format)
    static func buildBatchLookupResults(
        indexResults: [IndexResult],
        packageData: [Int64: ChunkPackageData]
    ) -> [[String: Any]] {
        var jsonResults: [[String: Any]] = []
        
        for indexRow in indexResults {
            guard let data = packageData[indexRow.hashId] else {
                continue
            }
            
            let iosSupport = PlatformSupportCategory(rawValue: data.iosSupport) ?? .unknown
            let androidSupport = PlatformSupportCategory(rawValue: data.androidSupport) ?? .unknown
            let source = PackageSourceIndex(rawValue: data.source) ?? .pypi
            let category = PackageCategoryType(rawValue: data.category) ?? .unprocessed
            
            let result: [String: Any] = [
                "name": indexRow.name,
                "ios": iosSupport.jsValue,
                "android": androidSupport.jsValue,
                "ios_version": data.iosVersion ?? "",
                "android_version": data.androidVersion ?? "",
                "category": category.categoryDisplayName(source: source),
                "source": source.displayName,
                "downloads": data.downloads,
                "latest_version": data.latestVersion ?? ""
            ]
            jsonResults.append(result)
        }
        
        return jsonResults
    }
    
    deinit {
        // SQLChunk deinit will handle closing databases
        chunkDatabases.removeAll()
    }   
}