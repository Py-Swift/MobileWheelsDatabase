import Foundation
import CSQLite

/// Swift WASM module that queries SQLite directly
/// JavaScript loads database file and passes bytes to Swift
/// Swift uses native SQLite to query and return JSON

// Import console logging from JavaScript
@_extern(wasm, module: "env", name: "consoleLog")
@_extern(c)
func consoleLog(_ messagePtr: UnsafeRawPointer, _ messageLen: Int32)

// Global database managers
private let indexDatabases = IndexDatabases()
private var jsonOutputBuffer: [UInt8] = [] // Swift-managed output buffer separate from WASM memory

private func log(_ message: String) {
    let utf8 = Array(message.utf8)
    utf8.withUnsafeBufferPointer { ptr in
        consoleLog(ptr.baseAddress!, Int32(utf8.count))
    }
}

// Initialize Swift WASM and load SQLite database from memory
@_expose(wasm, "swiftInit")
@_cdecl("swiftInit")
public func swiftInit(_ dbPtr: UnsafeRawPointer, _ dbSize: Int32) -> Int32 {
    log("🚀 Swift WASM initializing with database (\(dbSize) bytes)...")
    
    guard indexDatabases.loadIndex1(dbPtr: dbPtr, dbSize: Int(dbSize)) else {
        log("❌ Failed to load index database")
        return 0
    }
    
    log("✅ SQLite database loaded successfully")
    
    let count = indexDatabases.getIndex1Count()
    log("✅ Database verified: \(count) packages in index")
    
    return 1
}

// Attach the second index database
@_expose(wasm, "swiftAttachIndex2")
@_cdecl("swiftAttachIndex2")
public func swiftAttachIndex2(_ dbPtr: UnsafeRawPointer, _ dbSize: Int32) -> Int32 {
    log("📎 Attaching second index database (\(dbSize) bytes)...")
    
    guard indexDatabases.loadIndex2(dbPtr: dbPtr, dbSize: Int(dbSize)) else {
        log("❌ Failed to load index2 database")
        return 0
    }
    
    let count = indexDatabases.getIndex2Count()
    log("✅ Index2 loaded: \(count) packages")
    log("✅ Second index database loaded (will be queried separately)")
    return 1
}

// Attach a data chunk database using SQLChunks singleton
@_expose(wasm, "swiftAttachChunk")
@_cdecl("swiftAttachChunk")
public func swiftAttachChunk(_ chunkNum: Int32, _ dbPtr: UnsafeRawPointer, _ dbSize: Int32) -> Int32 {
    log("📎 Attaching data chunk \(chunkNum) (\(dbSize) bytes)...")
    
    let success = SQLChunks.shared.loadChunk(
        chunkNum: Int(chunkNum),
        dbPtr: dbPtr,
        dbSize: Int(dbSize)
    )
    
    if success {
        log("✅ Data chunk \(chunkNum) attached successfully")
        return 1
    } else {
        log("❌ Failed to attach chunk \(chunkNum)")
        return 0
    }
}

// Return code indicating chunk needed: -chunkNum
// e.g., -5 means "load chunk 5 then call again"

// Search packages using native SQLite queries
@_expose(wasm, "swiftSearch")
@_cdecl("swiftSearch")
public func swiftSearch(_ queryPtr: UnsafeRawPointer, _ queryLen: Int32, _ outputPtr: UnsafeMutablePointer<UInt8>, _ outputLen: Int32) -> Int32 {
    log("🔍 swiftSearch called with queryLen: \(queryLen)")
    
    // Read query string from memory
    let queryBytes = UnsafeBufferPointer(start: queryPtr.assumingMemoryBound(to: UInt8.self), count: Int(queryLen))
    
    guard let query = String(bytes: queryBytes, encoding: .utf8), !query.isEmpty else {
        log("❌ Invalid query string")
        return 0
    }
    
    log("🔍 Searching for: \(query)")
    
    // Search indexes
    log("📋 Searching indexes...")
    var indexResults = indexDatabases.searchPackages(query: query, limit: 1000)
    log("📊 Found \(indexResults.count) packages in index")
    
    guard !indexResults.isEmpty else { return 0 }
    
    // Sort by relevance
    indexResults = SQLChunks.sortByRelevance(results: indexResults, query: query)
    
    // Limit to 1000 results
    if indexResults.count > 1000 {
        indexResults = Array(indexResults.prefix(1000))
    }
    
    // Group by chunk
    let groupedPackages = PackagesByChunk(from: indexResults)
    let sortedChunkNums = groupedPackages.chunkNumbers
    log("📊 Need to query \(sortedChunkNums.count) data chunks: \(sortedChunkNums)")
    
    // Check which chunks need loading
    let neededChunks = Set(sortedChunkNums)
    let unloadedChunks = SQLChunks.shared.getMissingChunks(from: neededChunks)
    
    // If any chunks need loading, return them as comma-separated list
    if !unloadedChunks.isEmpty {
        let chunksToLoad = unloadedChunks.map { String($0) }.joined(separator: ",")
        log("⚠️ Need to load \(unloadedChunks.count) chunks: [\(chunksToLoad)]")
        let needChunkMsg = "-\(chunksToLoad)"
        if let data = needChunkMsg.data(using: .utf8) {
            let bytesToWrite = min(data.count, Int(outputLen))
            data.withUnsafeBytes { bytes in
                outputPtr.update(from: bytes.bindMemory(to: UInt8.self).baseAddress!, count: bytesToWrite)
            }
            return Int32(bytesToWrite)
        }
        return 0
    }
    
    // All chunks loaded - query them
    log("📊 Querying \(groupedPackages.packages.count) chunks...")
    let allData = SQLChunks.shared.queryPackages(packagesByChunk: groupedPackages.packages)
    log("📊 Collected data for \(allData.count) packages")
    
    // Build JSON results
    log("🔨 Building JSON results...")
    let jsonResults = SQLChunks.buildSearchResults(indexResults: indexResults, packageData: allData)
    log("📊 Built \(jsonResults.count) JSON results")
    
    // Encode to JSON
    log("🔧 Encoding JSON...")
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonResults)
        jsonOutputBuffer = Array(jsonData)
        
        let bytesToWrite = min(jsonOutputBuffer.count, Int(outputLen))
        for i in 0..<bytesToWrite {
            outputPtr[i] = jsonOutputBuffer[i]
        }
        
        log("✅ Returning \(jsonResults.count) results (\(bytesToWrite) bytes)")
        return Int32(bytesToWrite)
    } catch {
        log("❌ Failed to encode JSON: \(error)")
        return 0
    }
}

// Batch lookup packages by exact names (for analyze requirements)
@_expose(wasm, "swiftBatchLookup")
@_cdecl("swiftBatchLookup")
public func swiftBatchLookup(_ namesPtr: UnsafeRawPointer, _ namesLen: Int32, _ outputPtr: UnsafeMutablePointer<UInt8>, _ outputLen: Int32) -> Int32 {
    log("📦 swiftBatchLookup called with namesLen: \(namesLen)")
    
    // Read JSON array of package names from memory
    let namesBytes = UnsafeBufferPointer(start: namesPtr.assumingMemoryBound(to: UInt8.self), count: Int(namesLen))
    
    guard let jsonString = String(bytes: namesBytes, encoding: .utf8),
          let jsonData = jsonString.data(using: .utf8),
          let packageNames = try? JSONDecoder().decode([String].self, from: jsonData) else {
        log("❌ Invalid package names JSON")
        return 0
    }
    
    log("📋 Looking up \(packageNames.count) packages")
    
    // Lookup packages in indexes
    let indexResults = indexDatabases.lookupPackages(names: packageNames)
    log("📋 Found \(indexResults.count) packages in index")
    
    // Group by chunk
    let groupedPackages = PackagesByChunk(from: indexResults)
    let neededChunks = Set(groupedPackages.chunkNumbers)
    let missingChunks = SQLChunks.shared.getMissingChunks(from: neededChunks)
    
    // If any chunks are missing, return a request for them
    if !missingChunks.isEmpty {
        let chunkRequest = "-" + missingChunks.map { String($0) }.joined(separator: ",")
        log("📥 Requesting chunks: \(chunkRequest)")
        
        let requestBytes = Array(chunkRequest.utf8)
        let bytesToWrite = min(requestBytes.count, Int(outputLen))
        for i in 0..<bytesToWrite {
            outputPtr[i] = requestBytes[i]
        }
        return Int32(bytesToWrite)
    }
    
    // All chunks loaded - query them
    log("📊 Querying \(groupedPackages.packages.count) chunks...")
    let allData = SQLChunks.shared.queryPackages(packagesByChunk: groupedPackages.packages)
    log("📊 Collected data for \(allData.count) packages")
    
    // Build JSON results
    let jsonResults = SQLChunks.buildBatchLookupResults(indexResults: indexResults, packageData: allData)
    log("🔨 Built \(jsonResults.count) results")
    
    // Encode to JSON
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: jsonResults, options: [])
        jsonOutputBuffer = Array(jsonData)
        
        let bytesToWrite = min(jsonOutputBuffer.count, Int(outputLen))
        for i in 0..<bytesToWrite {
            outputPtr[i] = jsonOutputBuffer[i]
        }
        
        log("✅ Returning \(jsonResults.count) results (\(bytesToWrite) bytes)")
        return Int32(bytesToWrite)
    } catch {
        log("❌ Failed to encode JSON: \(error)")
        return 0
    }
}

// Simple test function
@_expose(wasm, "swiftTest")
@_cdecl("swiftTest")
public func swiftTest() -> Int32 {
    return 42
}

