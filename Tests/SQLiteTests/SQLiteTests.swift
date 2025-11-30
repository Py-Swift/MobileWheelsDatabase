import XCTest
import SQLite

final class SQLiteTests: XCTestCase {
    
    var db: Connection!
    
    override func setUp() {
        super.setUp()
        // Create a new in-memory database for each test
        db = try! Connection(.inMemory)
    }
    
    override func tearDown() {
        db = nil
        super.tearDown()
    }
    
    func testCreateTable() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        
        // Create table should not throw
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
        })
        
        // Verify table exists by querying schema
        let schemaQuery = try db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")
        var tables: [[Binding?]] = []
        for row in schemaQuery {
            tables.append(row)
        }
        XCTAssertEqual(tables.count, 1, "Table should exist")
    }
    
    func testInsertAndQuery() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        let email = Expression<String?>("email")
        
        // Create table
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(email, unique: true)
        })
        
        // Insert data
        let rowid = try db.run(users.insert(name <- "Alice", email <- "alice@example.com"))
        XCTAssertEqual(rowid, 1, "First insert should have rowid 1")
        
        // Query data
        var rows: [Row] = []
        for row in try db.prepare(users) {
            rows.append(row)
        }
        
        XCTAssertEqual(rows.count, 1, "Should have exactly one row")
        XCTAssertEqual(rows[0][name], "Alice", "Name should match")
        XCTAssertEqual(rows[0][email], "alice@example.com", "Email should match")
    }
    
    func testMultipleInserts() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
        })
        
        // Insert multiple rows
        try db.run(users.insert(name <- "Alice"))
        try db.run(users.insert(name <- "Bob"))
        try db.run(users.insert(name <- "Charlie"))
        
        // Query all
        var rows: [Row] = []
        for row in try db.prepare(users) {
            rows.append(row)
        }
        
        XCTAssertEqual(rows.count, 3, "Should have three rows")
        
        let names = rows.map { $0[name] }
        XCTAssertTrue(names.contains("Alice"))
        XCTAssertTrue(names.contains("Bob"))
        XCTAssertTrue(names.contains("Charlie"))
    }
    
    func testUpdate() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        let age = Expression<Int>("age")
        
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(age)
        })
        
        // Insert
        let alice = try db.run(users.insert(name <- "Alice", age <- 30))
        
        // Update
        let aliceRow = users.filter(id == alice)
        try db.run(aliceRow.update(age <- 31))
        
        // Verify
        let result = try db.pluck(aliceRow)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?[age], 31, "Age should be updated")
    }
    
    func testDelete() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
        })
        
        // Insert
        let alice = try db.run(users.insert(name <- "Alice"))
        try db.run(users.insert(name <- "Bob"))
        
        // Delete Alice
        let aliceRow = users.filter(id == alice)
        try db.run(aliceRow.delete())
        
        // Verify
        var remaining: [Row] = []
        for row in try db.prepare(users) {
            remaining.append(row)
        }
        XCTAssertEqual(remaining.count, 1, "Should have one row left")
        XCTAssertEqual(remaining[0][name], "Bob", "Bob should remain")
    }
    
    func testFilterAndCount() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        let active = Expression<Bool>("active")
        
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(active)
        })
        
        // Insert test data
        try db.run(users.insert(name <- "Alice", active <- true))
        try db.run(users.insert(name <- "Bob", active <- false))
        try db.run(users.insert(name <- "Charlie", active <- true))
        
        // Filter active users
        let activeUsers = users.filter(active == true)
        let count = try db.scalar(activeUsers.count)
        
        XCTAssertEqual(count, 2, "Should have 2 active users")
        
        // Verify names
        let activeNames = try db.prepare(activeUsers).map { $0[name] }
        XCTAssertTrue(activeNames.contains("Alice"))
        XCTAssertTrue(activeNames.contains("Charlie"))
        XCTAssertFalse(activeNames.contains("Bob"))
    }
    
    func testCSQLiteIntegration() throws {
        // Verify we're using the custom CSQLite module
        // by testing basic functionality works
        
        let version = try db.scalar("SELECT sqlite_version()") as! String
        XCTAssertFalse(version.isEmpty, "Should return SQLite version")
        XCTAssertTrue(version.contains("."), "Version should have dots")
    }
    
    func testTransaction() throws {
        let users = Table("users")
        let id = Expression<Int64>("id")
        let name = Expression<String>("name")
        
        try db.run(users.create { t in
            t.column(id, primaryKey: true)
            t.column(name)
        })
        
        // Test successful transaction
        try db.transaction {
            try db.run(users.insert(name <- "Alice"))
            try db.run(users.insert(name <- "Bob"))
        }
        
        var count = try db.scalar(users.count)
        XCTAssertEqual(count, 2, "Both inserts should be committed")
        
        // Test rolled back transaction
        do {
            try db.transaction {
                try db.run(users.insert(name <- "Charlie"))
                throw NSError(domain: "test", code: 1)
            }
        } catch {
            // Expected to fail
        }
        
        count = try db.scalar(users.count)
        XCTAssertEqual(count, 2, "Charlie insert should be rolled back")
    }
}
