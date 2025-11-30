# Mobile Wheels SQLite Database

This folder contains a chunked SQLite database of Python package compatibility with mobile platforms (Android & iOS).

## 📊 Database Statistics

- **Total Packages**: 715.773
- **Data Chunks**: 15 files (~50,000 packages each)
- **Chunk Size**: ~9-10 MB per file (optimized for lazy loading)
- **All files**: Under 100 MB (GitHub LFS compatible)

## 📁 File Structure

```
mobile-wheels-sql/
├── README.md           ← You are here
├── index.sqlite        ← Package name → hash_id → chunk_file lookup (~50 MB)
├── data-1.sqlite       ← Package data chunk 1 (~9-10 MB)
├── data-2.sqlite       ← Package data chunk 2 (~9-10 MB)
└── ...
```

**Why small chunks?** Optimized for web/JavaScript lazy loading:
- Load only index.sqlite initially (~50 MB)
- Load specific data chunk on-demand (~9-10 MB each)
- Fast single package lookups without downloading all data
- Better caching and bandwidth efficiency

## 🗂️ Database Schema

### `index.sqlite` - Package Index
**Table**: `package_index`
```sql
CREATE TABLE package_index (
    name TEXT PRIMARY KEY,      -- Package name (e.g., 'numpy')
    hash_id INTEGER,            -- Hash identifier
    chunk_file INTEGER          -- Which data-N.sqlite file contains this package
);
```

### `data-N.sqlite` - Package Data Chunks
**Table**: `package_data`
```sql
CREATE TABLE package_data (
    hash_id INTEGER PRIMARY KEY,
    downloads INTEGER,
    android_support INTEGER,    -- 1=Binary, 2=Pure Python, 3=Both
    ios_support INTEGER,        -- 1=Binary, 2=Pure Python, 3=Both
    source TEXT,
    category TEXT,
    android_version TEXT,
    ios_version TEXT,
    latest_version TEXT,
    dependency_status TEXT,
    dependencies BLOB,          -- Raw bytes: Int64 array (8 bytes per hash_id)
    dependency_count INTEGER    -- Count for quick filtering
);
```

**Note**: Dependencies are stored as a BLOB of Int64 values (8 bytes each), not JSON. 
- Empty dependencies = NULL
- Otherwise: Binary data with `dependency_count * 8` bytes
- More efficient than JSON (no parsing overhead, smaller size)

## 🔍 Query Examples

### 1. Find a Package and Get Its Details

```sql
-- Step 1: Look up the package in the index
SELECT hash_id, chunk_file 
FROM package_index 
WHERE name = 'numpy';
-- Result: hash_id=-3416350691657239290, chunk_file=1

-- Step 2: Open the appropriate data chunk and fetch details
-- (Open data-1.sqlite)
SELECT * 
FROM package_data 
WHERE hash_id = -3416350691657239290;
```

### 2. Find Packages with Dependencies

```sql
-- Open any data-N.sqlite file
SELECT hash_id, dependency_count 
FROM package_data 
WHERE dependency_count > 10
ORDER BY dependency_count DESC
LIMIT 10;
```

### 3. Resolve Dependencies to Package Names

```sql
-- Get dependencies BLOB from data file
SELECT dependencies, dependency_count
FROM package_data 
WHERE hash_id = -7630557452949343832;
-- Result: BLOB of binary data (dependency_count * 8 bytes)

-- To read in SQLite CLI, you need to parse the BLOB
-- This is easier in programming languages (see examples below)

-- Look up dependency names in index (after extracting hash_ids)
SELECT name 
FROM package_index 
WHERE hash_id IN (-1902500900751896792, 9208656938782387101, ...);
-- Result: aiohttp, argon2-cffi-bindings, ...
```

### 4. Find Pure Python Packages

```sql
-- Open any data-N.sqlite file
SELECT hash_id, dependency_count
FROM package_data 
WHERE android_support = 2 AND ios_support = 2;

-- Then look up names in index.sqlite
SELECT name 
FROM package_index 
WHERE hash_id IN (...);
```

## 💻 JavaScript Example (for MkDocs/Web)

```javascript
// Using sql.js (https://github.com/sql-js/sql.js)

class MobileWheelsDB {
    constructor() {
        this.indexDB = null;
        this.dataDBs = {}; // Cache for loaded data chunks
    }
    
    async init() {
        // Load index database
        const indexBuffer = await fetch('index.sqlite').then(r => r.arrayBuffer());
        this.indexDB = new SQL.Database(new Uint8Array(indexBuffer));
    }
    
    async loadDataChunk(chunkNum) {
        if (!this.dataDBs[chunkNum]) {
            const buffer = await fetch(`data-${chunkNum}.sqlite`).then(r => r.arrayBuffer());
            this.dataDBs[chunkNum] = new SQL.Database(new Uint8Array(buffer));
        }
        return this.dataDBs[chunkNum];
    }
    
    async getPackage(packageName) {
        // Step 1: Look up in index
        const indexResult = this.indexDB.exec(
            `SELECT hash_id, chunk_file FROM package_index WHERE name = ?`,
            [packageName]
        );
        
        if (indexResult.length === 0) return null;
        
        const [hashId, chunkFile] = indexResult[0].values[0];
        
        // Step 2: Load appropriate chunk and fetch data
        const dataDB = await this.loadDataChunk(chunkFile);
        const dataResult = dataDB.exec(
            `SELECT * FROM package_data WHERE hash_id = ?`,
            [hashId]
        );
        
        if (dataResult.length === 0) return null;
        
        const row = dataResult[0].values[0];
        
        // Parse dependencies BLOB (Int64 array, 8 bytes each)
        const dependenciesBlob = row[10]; // BLOB or null
        let dependencies = [];
        if (dependenciesBlob && dependenciesBlob.length > 0) {
            const view = new DataView(dependenciesBlob.buffer);
            const count = dependenciesBlob.length / 8;
            for (let i = 0; i < count; i++) {
                dependencies.push(view.getBigInt64(i * 8, true)); // little-endian
            }
        }
        
        return {
            name: packageName,
            hashId: hashId,
            downloads: row[1],
            androidSupport: row[2],
            iosSupport: row[3],
            latestVersion: row[8],
            dependencies: dependencies,
            dependencyCount: row[11]
        };
    }
    
    async resolveDependencies(depHashIds) {
        if (depHashIds.length === 0) return [];
        
        const placeholders = depHashIds.map(() => '?').join(',');
        const result = this.indexDB.exec(
            `SELECT hash_id, name FROM package_index WHERE hash_id IN (${placeholders})`,
            depHashIds
        );
        
        if (result.length === 0) return [];
        
        return result[0].values.map(row => ({
            hashId: row[0],
            name: row[1]
        }));
    }
}

// Usage
const db = new MobileWheelsDB();
await db.init();

const pkg = await db.getPackage('numpy');
console.log(pkg);

if (pkg.dependencies.length > 0) {
    const deps = await db.resolveDependencies(pkg.dependencies);
    console.log('Dependencies:', deps);
}
```

## 🐍 Python Example

```python
import sqlite3
import json

class MobileWheelsDB:
    def __init__(self, folder_path):
        self.folder = folder_path
        self.index_conn = sqlite3.connect(f'{folder_path}/index.sqlite')
        self.data_conns = {}  # Cache for data chunk connections
    
    def get_data_connection(self, chunk_num):
        if chunk_num not in self.data_conns:
            self.data_conns[chunk_num] = sqlite3.connect(
                f'{self.folder}/data-{chunk_num}.sqlite'
            )
        return self.data_conns[chunk_num]
    
    def get_package(self, package_name):
        # Look up in index
        cursor = self.index_conn.execute(
            'SELECT hash_id, chunk_file FROM package_index WHERE name = ?',
            (package_name,)
        )
        result = cursor.fetchone()
        
        if not result:
            return None
        
        hash_id, chunk_file = result
        
        # Fetch from appropriate data chunk
        data_conn = self.get_data_connection(chunk_file)
        cursor = data_conn.execute(
            'SELECT * FROM package_data WHERE hash_id = ?',
            (hash_id,)
        )
        row = cursor.fetchone()
        
        if not row:
            return None
        
        # Parse dependencies BLOB (Int64 array, 8 bytes each)
        dependencies = []
        if row[10]:  # dependencies BLOB
            import struct
            blob = row[10]
            count = len(blob) // 8
            dependencies = list(struct.unpack(f'<{count}q', blob))  # little-endian int64
        
        return {
            'hash_id': row[0],
            'downloads': row[1],
            'android_support': row[2],
            'ios_support': row[3],
            'latest_version': row[8],
            'dependencies': dependencies,
            'dependency_count': row[11]
        }
    
    def resolve_dependencies(self, dep_hash_ids):
        if not dep_hash_ids:
            return []
        
        placeholders = ','.join('?' * len(dep_hash_ids))
        cursor = self.index_conn.execute(
            f'SELECT hash_id, name FROM package_index WHERE hash_id IN ({placeholders})',
            dep_hash_ids
        )
        return [{'hash_id': row[0], 'name': row[1]} for row in cursor.fetchall()]
    
    def close(self):
        self.index_conn.close()
        for conn in self.data_conns.values():
            conn.close()

# Usage
db = MobileWheelsDB('mobile-wheels-sql')

pkg = db.get_package('numpy')
print(f"Package: {pkg}")

if pkg['dependencies']:
    deps = db.resolve_dependencies(pkg['dependencies'])
    print(f"Dependencies: {deps}")

db.close()
```

## 🎯 Common Use Cases

### Search by Platform Support
```sql
-- Find packages that work on both Android and iOS
SELECT name FROM package_index 
WHERE hash_id IN (
    SELECT hash_id FROM package_data 
    WHERE android_support IN (2,3) AND ios_support IN (2,3)
);
```

### Get Dependency Tree
1. Look up package in index → get hash_id and chunk_file
2. Load data chunk → get dependencies array
3. For each dependency hash_id → look up name in index
4. Repeat for nested dependencies

### Filter by Dependency Count
```sql
-- Packages with no dependencies (easiest to use on mobile)
SELECT name FROM package_index 
WHERE hash_id IN (
    SELECT hash_id FROM package_data 
    WHERE dependency_count = 0
);
```

## 📝 Support Values Reference

- **android_support / ios_support**:
  - `1` = Binary Only (compiled wheels available)
  - `2` = Pure Python (works everywhere)
  - `3` = Both (has both binary and pure Python support)

## 🔧 Tools Required

- **SQLite**: Any SQLite3 client (command-line, Python's `sqlite3`, Node.js, etc.)
- **JavaScript**: [sql.js](https://github.com/sql-js/sql.js) for browser usage
- **Python**: Built-in `sqlite3` module

## 📄 License

This database is part of the MobilePlatformSupport project.
Repository: https://github.com/Py-Swift/MobilePlatformSupport

---

Generated on 30 November 2025 at 3.10