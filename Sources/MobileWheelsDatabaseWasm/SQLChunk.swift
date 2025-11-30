import Foundation
import CSQLite

/// Package data retrieved from a chunk
struct ChunkPackageData {
    let hashId: Int64
    let downloads: Int
    let androidSupport: Int
    let iosSupport: Int
    let source: Int
    let category: Int
    let androidVersion: String?
    let iosVersion: String?
    let latestVersion: String?
}

/// Represents a single SQLite chunk with its database handle and metadata
final class SQLChunk {
    let chunkNum: Int
    let db: OpaquePointer
    let size: Int
    private(set) var loadedAt: Date
    
    private init(chunkNum: Int, db: OpaquePointer, size: Int) {
        self.chunkNum = chunkNum
        self.db = db
        self.size = size
        self.loadedAt = Date()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    /// Load a chunk from JavaScript-provided bytes
    static func load(chunkNum: Int, dbPtr: UnsafeRawPointer, dbSize: Int) -> SQLChunk? {
        // Copy chunk bytes to mutable memory
        let dbBytes = UnsafeRawBufferPointer(start: dbPtr, count: dbSize)
        let mutableCopy = UnsafeMutableRawBufferPointer.allocate(byteCount: dbSize, alignment: 1)
        mutableCopy.copyBytes(from: dbBytes)
        
        // Open in-memory database
        var chunkDb: OpaquePointer? = nil
        var rc = sqlite3_open(":memory:", &chunkDb)
        
        guard rc == SQLITE_OK, let openedChunkDb = chunkDb else {
            return nil
        }
        
        // Deserialize chunk data
        rc = sqlite3_deserialize(
            openedChunkDb,
            "main",
            mutableCopy.baseAddress?.assumingMemoryBound(to: UInt8.self),
            sqlite3_int64(dbSize),
            sqlite3_int64(dbSize),
            UInt32(SQLITE_DESERIALIZE_FREEONCLOSE)
        )
        
        if rc != SQLITE_OK {
            sqlite3_close(openedChunkDb)
            return nil
        }
        
        return SQLChunk(chunkNum: chunkNum, db: openedChunkDb, size: dbSize)
    }
    
    /// Query package data by hash IDs
    func queryPackages(hashIds: [Int64]) -> [ChunkPackageData] {
        guard !hashIds.isEmpty else { return [] }
        
        let hashIdsList = hashIds.map { String($0) }.joined(separator: ",")
        let dataSQL = """
            SELECT hash_id, downloads, android_support, ios_support, source, category,
                   android_version, ios_version, latest_version
            FROM package_data
            WHERE hash_id IN (\(hashIdsList))
        """
        
        var dataStmt: OpaquePointer? = nil
        let rc = sqlite3_prepare_v2(db, dataSQL, -1, &dataStmt, nil)
        
        guard rc == SQLITE_OK, let stmt = dataStmt else {
            return []
        }
        
        defer { sqlite3_finalize(stmt) }
        
        var results: [ChunkPackageData] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let data = ChunkPackageData(
                hashId: sqlite3_column_int64(stmt, 0),
                downloads: Int(sqlite3_column_int(stmt, 1)),
                androidSupport: Int(sqlite3_column_int(stmt, 2)),
                iosSupport: Int(sqlite3_column_int(stmt, 3)),
                source: Int(sqlite3_column_int(stmt, 4)),
                category: Int(sqlite3_column_int(stmt, 5)),
                androidVersion: sqlite3_column_text(stmt, 6).map { String(cString: $0) },
                iosVersion: sqlite3_column_text(stmt, 7).map { String(cString: $0) },
                latestVersion: sqlite3_column_text(stmt, 8).map { String(cString: $0) }
            )
            results.append(data)
        }
        
        return results
    }
}
