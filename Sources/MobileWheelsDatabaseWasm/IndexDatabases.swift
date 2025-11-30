import Foundation
import CSQLite

/// Index search result
struct IndexResult {
    let name: String
    let hashId: Int64
    let chunkFile: Int
}

/// Manages the two index databases and provides search functionality
final class IndexDatabases {
    private var index1Db: OpaquePointer?
    private var index2Db: OpaquePointer?
    
    /// Load the primary index database
    func loadIndex1(dbPtr: UnsafeRawPointer, dbSize: Int) -> Bool {
        var tempDb: OpaquePointer? = nil
        var rc = sqlite3_open(":memory:", &tempDb)
        
        guard rc == SQLITE_OK, let openedDb = tempDb else {
            sqlite3_close(tempDb)
            return false
        }
        
        let dbBytes = UnsafeRawBufferPointer(start: dbPtr, count: dbSize)
        let mutableCopy = UnsafeMutableRawBufferPointer.allocate(byteCount: dbSize, alignment: 1)
        mutableCopy.copyBytes(from: dbBytes)
        
        rc = sqlite3_deserialize(
            openedDb,
            "main",
            mutableCopy.baseAddress?.assumingMemoryBound(to: UInt8.self),
            sqlite3_int64(dbSize),
            sqlite3_int64(dbSize),
            UInt32(SQLITE_DESERIALIZE_FREEONCLOSE)
        )
        
        if rc != SQLITE_OK {
            sqlite3_close(openedDb)
            return false
        }
        
        index1Db = openedDb
        return true
    }
    
    /// Load the secondary index database
    func loadIndex2(dbPtr: UnsafeRawPointer, dbSize: Int) -> Bool {
        var tempDb: OpaquePointer? = nil
        var rc = sqlite3_open(":memory:", &tempDb)
        
        guard rc == SQLITE_OK, let openedDb = tempDb else {
            sqlite3_close(tempDb)
            return false
        }
        
        let dbBytes = UnsafeRawBufferPointer(start: dbPtr, count: dbSize)
        let mutableCopy = UnsafeMutableRawBufferPointer.allocate(byteCount: dbSize, alignment: 1)
        mutableCopy.copyBytes(from: dbBytes)
        
        rc = sqlite3_deserialize(
            openedDb,
            "main",
            mutableCopy.baseAddress?.assumingMemoryBound(to: UInt8.self),
            Int64(dbSize),
            Int64(dbSize),
            UInt32(SQLITE_DESERIALIZE_FREEONCLOSE | SQLITE_DESERIALIZE_RESIZEABLE)
        )
        
        if rc != SQLITE_OK {
            sqlite3_close(openedDb)
            return false
        }
        
        index2Db = openedDb
        return true
    }
    
    /// Search for packages with LIKE query
    func searchPackages(query: String, limit: Int = 1000) -> [IndexResult] {
        let escapedQuery = query.replacingOccurrences(of: "'", with: "''")
        let indexSQL = String(format: "SELECT name, hash_id, chunk_file FROM package_index WHERE name LIKE '%%%@%%' LIMIT %d", escapedQuery, limit)
        
        var results: [IndexResult] = []
        
        // Search index1
        if let db = index1Db {
            results.append(contentsOf: queryIndex(db: db, sql: indexSQL))
        }
        
        // Search index2
        if let db = index2Db {
            results.append(contentsOf: queryIndex(db: db, sql: indexSQL))
        }
        
        return results
    }
    
    /// Batch lookup packages by exact names (case-insensitive)
    func lookupPackages(names: [String]) -> [IndexResult] {
        var results: [IndexResult] = []
        
        // Process in batches of 100
        let batchSize = 100
        for batchStart in stride(from: 0, to: names.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, names.count)
            let batch = Array(names[batchStart..<batchEnd])
            
            let escapedNames = batch.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }
            let namesList = escapedNames.joined(separator: ",")
            // Use LOWER() for case-insensitive matching
            let indexSQL = "SELECT name, hash_id, chunk_file FROM package_index WHERE LOWER(name) IN (\(namesList))"
            
            // Query both indexes
            if let db = index1Db {
                results.append(contentsOf: queryIndex(db: db, sql: indexSQL))
            }
            if let db = index2Db {
                results.append(contentsOf: queryIndex(db: db, sql: indexSQL))
            }
        }
        
        return results
    }
    
    /// Count packages in index1
    func getIndex1Count() -> Int {
        guard let db = index1Db else { return 0 }
        
        var countStmt: OpaquePointer? = nil
        let sql = "SELECT COUNT(*) FROM package_index"
        let rc = sqlite3_prepare_v2(db, sql, -1, &countStmt, nil)
        
        guard rc == SQLITE_OK, let stmt = countStmt else {
            return 0
        }
        
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        
        return 0
    }
    
    /// Count packages in index2
    func getIndex2Count() -> Int {
        guard let db = index2Db else { return 0 }
        
        var countStmt: OpaquePointer? = nil
        let sql = "SELECT COUNT(*) FROM package_index"
        let rc = sqlite3_prepare_v2(db, sql, -1, &countStmt, nil)
        
        guard rc == SQLITE_OK, let stmt = countStmt else {
            return 0
        }
        
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        
        return 0
    }
    
    // MARK: - Private helpers
    
    private func queryIndex(db: OpaquePointer, sql: String) -> [IndexResult] {
        var results: [IndexResult] = []
        var stmt: OpaquePointer? = nil
        
        let rc = sql.withCString { sqlPtr in
            sqlite3_prepare_v2(db, sqlPtr, -1, &stmt, nil)
        }
        
        guard rc == SQLITE_OK, let statement = stmt else {
            return results
        }
        
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let nameCStr = sqlite3_column_text(statement, 0) else { continue }
            let name = String(cString: nameCStr)
            let hashId = sqlite3_column_int64(statement, 1)
            let chunkFile = Int(sqlite3_column_int(statement, 2))
            results.append(IndexResult(name: name, hashId: hashId, chunkFile: chunkFile))
        }
        
        return results
    }
    
    deinit {
        if let db = index1Db {
            sqlite3_close(db)
        }
        if let db = index2Db {
            sqlite3_close(db)
        }
    }
}
