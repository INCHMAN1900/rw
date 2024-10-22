//
//  RWFileModel.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import SwiftUI
import SQLite

typealias SQLiteExpression = SQLite.Expression


class RWFileModel {
    static let table = Table("rw_file")
    static let logger = Logger(name: "RWFileModel")

    struct Column {
        static let id = SQLiteExpression<Int64>("id")
        static let path = SQLiteExpression<String>("path")
        static let contentType = SQLiteExpression<String>("content_type")
        static let size = SQLiteExpression<Int>("allocated_size")
        static let creationDate = SQLiteExpression<Int64>("creation_date")
        static let modificationDate = SQLiteExpression<Int64>("modification_date")
        static let createdAt = SQLiteExpression<Int64>("created_at")
    }
    
    struct Entity: Identifiable {
        let id: Int64
        var path: String
        var contentType: String
        var size: Int
        var creationDate: Int64
        var modificationDate: Int64
        var createdAt: Int64
        
        var setter: [Setter] {
            let now = Int64(Date().timeIntervalSince1970)
            let setter = [
                Column.path                 <- path,
                Column.contentType          <- contentType,
                Column.size                 <- size,
                Column.creationDate         <- creationDate,
                Column.modificationDate     <- modificationDate,
                Column.createdAt            <- now,
            ]
            return setter
        }
        
        static func from(row: Row) -> Entity {
            return Entity(
                id:                 row[Column.id],
                path:               row[Column.path],
                contentType:        row[Column.contentType],
                size:               row[Column.size],
                creationDate:       row[Column.creationDate],
                modificationDate:   row[Column.modificationDate],
                createdAt:          row[Column.createdAt]
            )
        }
        
        static func from(url: URL) -> Entity? {
            guard
                FileManager.default.fileExists(atPath: url.path)
            else {
                return Entity(
                    id: -1,
                    path: url.path(percentEncoded: false),
                    contentType: "",
                    size: 0,
                    creationDate: -1,
                    modificationDate: Date().timestamp,
                    createdAt: Date().timestamp
                )
            }
            let resourceKeys: Set<URLResourceKey> = [
                .contentTypeKey,
                .totalFileSizeKey,
                .creationDateKey,
                .contentModificationDateKey,
            ]
            guard let resourceValues = try? url.resourceValues(forKeys: resourceKeys) else { return nil}
            return Entity(
                id: -1,
                path: url.path(percentEncoded: false),
                contentType: resourceValues.contentType?.identifier ?? "",
                size: resourceValues.totalFileSize ?? 0,
                creationDate: resourceValues.creationDate?.timestamp ?? -1,
                modificationDate: resourceValues.contentModificationDate?.timestamp ?? -1,
                createdAt: Date().timestamp
            )
        }
    }

    public static func select(_ keyword: String, pageNumber: Int, pageSize: Int) -> (Int, [Entity]) {
        guard let db = SQLiteTools.getConnection() else { return (0, []) }
        do {
            var query = table
            let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if keyword != "" {
                query = query.filter(Column.path.like("%\(keyword)%"))
            }
            let count = try db.scalar(query.count)
            let rows = try db.prepare(
                query
                    .order(Column.createdAt.desc)
                    .limit(pageSize, offset: (pageNumber - 1) * pageSize)
            )
            return (count, rows.map({ Entity.from(row: $0) }))
        } catch {
            logger.log("Insert file failed: \(error.localizedDescription)")
        }
        return (0, [])
    }
    
    public static func insert(using path: String) {
        guard let db = SQLiteTools.getConnection() else { return }
        do {
            if let entity = Entity.from(url: URL(fileURLWithPath: path)) {
                try db.run(table.insert(entity.setter))
            }
        } catch {
            logger.log("Insert file failed: \(error.localizedDescription)")
        }
    }
    
    public static func insert(using paths: [String]) {
        guard let db = SQLiteTools.getConnection() else { return }
        do {
            var entities = [Entity]()
            for path in paths {
                if let entity = Entity.from(url: URL(fileURLWithPath: path)) {
                    entities.append(entity)
                }
            }
            try db.run(table.insertMany(entities.map({ $0.setter })))
        } catch {
            logger.log("Insert file failed: \(error.localizedDescription)")
        }
    }

    public static func createTable() throws {
        guard let connection = SQLiteTools.getConnection() else { return }
        try connection.run(table.create(ifNotExists: true) { t in
            t.column(Column.id, primaryKey: .autoincrement)
            t.column(Column.path)
            t.column(Column.contentType)
            t.column(Column.size)
            t.column(Column.creationDate)
            t.column(Column.modificationDate)
            t.column(Column.createdAt)
        })
        try connection.run(table.createIndex(Column.path, ifNotExists: true))
        try connection.run(table.createIndex(Column.contentType, ifNotExists: true))
        try connection.run(table.createIndex(Column.size, ifNotExists: true))
        try connection.run(table.createIndex(Column.creationDate, ifNotExists: true))
        try connection.run(table.createIndex(Column.modificationDate, ifNotExists: true))
        try connection.run(table.createIndex(Column.createdAt, ifNotExists: true))
    }
}