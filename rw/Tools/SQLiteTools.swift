//
//  SQLiteTools.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import Foundation
import SQLite

class SQLiteTools {
    static var connection: Connection?
    static var logger = Logger(name: "SQLiteTools")
    static var sqliteDirectory: URL? = nil
    
    static func getSQLitePath()-> URL? {
        do {
            var isDir : ObjCBool = true
            let directory = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("rw")
            if !FileManager.default.fileExists(atPath: directory.absoluteString, isDirectory: &isDir) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            sqliteDirectory = directory
            return directory
                .appendingPathComponent("rw.sqlite3")
        } catch let error {
            logger.log("getSQLitePath failed: \(error.localizedDescription)")
        }
        return nil
    }
    
    public static func getConnection()-> Connection? {
        if let connection {
            return connection
        }
        guard let dataPath = SQLiteTools.getSQLitePath()?.absoluteString else { return nil }
        do {
            connection = try Connection(dataPath)
            try RWFileModel.createTable()
            return connection
        } catch {
            logger.log("Failed to connect to database: \(error.localizedDescription)")
        }
        return nil
    }
    
    public static func ensureColumnExists(column: String, in table: String, addColumn: (() throws -> Void) ) {
        guard let connection else { return }
        
        do {
            if !(try connection.exists(column: column, in: table)) {
                try? addColumn()
            }
        } catch let error {
            logger.log("Ensure column existence failed for \(column) in \(table): \(error.localizedDescription)")
        }
    }
}

extension Connection {
    public func exists(column: String, in table: String) throws -> Bool {
        let stmt = try prepare("PRAGMA table_info(\(table))")
        
        let columnNames = stmt.makeIterator().map { row in
            return row[1] as? String ?? ""
        }
        
        return columnNames.contains(where: { dbColumn -> Bool in
            return dbColumn.caseInsensitiveCompare(column) == ComparisonResult.orderedSame
        })
    }
}
