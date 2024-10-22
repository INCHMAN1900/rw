//
//  RWMonitor.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import SwiftUI
import Foundation
import FileWatcher
import Combine

extension FileManager {
    /// Returns a Boolean value that indicates whether a directory exists at a specified path.
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory = ObjCBool(booleanLiteral: false)
        let fileExistsAtPath = fileExists(atPath: path, isDirectory: &isDirectory)
        return fileExistsAtPath && isDirectory.boolValue
    }
}

extension URL {
    /// Check if url is contained in current url
    func contains(_ url: URL) -> Bool {
        let urlComponents = url.pathComponents
        if urlComponents.count < pathComponents.count {
            return false
        }
        for i in 0..<pathComponents.count {
            if pathComponents[i] != urlComponents[i] {
                return false
            }
        }
        return true
    }
}

/// Monitors a directory subtree for file changes.
class RWMonitor {
    private var root = URL(fileURLWithPath: "/")
    private var fileWatcher: FileWatcher? = nil
    private var subscribers = [AnyCancellable]()
    
    init?() {
        if !FileManager.default.directoryExists(atPath: root.path) {
            return nil
        }
        
        fileWatcher = FileWatcher([root.path])
        fileWatcher?.callback = { event in
            if
                let sqliteDirectory = SQLiteTools.sqliteDirectory,
                event.path.starts(with: sqliteDirectory.path)
            {
                return
            }
            
            let includes = RWState.global.includes
            let excludes = RWState.global.excludes
            let fileURL = URL(fileURLWithPath: event.path)
            if includes.count > 0, !includes.contains(where: { $0.contains(fileURL) }) {
                return
            }
            if excludes.contains(where: { $0.contains(fileURL) }) {
                return
            }
            var eventType = RWEventType.unknown
            if event.fileCreated {
                eventType = .fileCreated
            }
            if event.fileRemoved {
                eventType = .fileRemoved
            }
            if event.fileRenamed {
                eventType = .fileRenamed
            }
            if event.fileModified {
                eventType = .fileChanged
            }
            if event.dirCreated {
                eventType = .dirCreated
            }
            if event.dirRemoved {
                eventType = .dirRemoved
            }
            if event.dirRenamed {
                eventType = .dirRenamed
            }
            if event.dirModified {
                eventType = .dirChanged
            }
            RWFileModel.insert(using: [event.path], for: eventType)
        }
        
        RWState.global.$isRunning
            .sink(receiveValue: { newValue in
                if newValue {
                    self.start()
                } else {
                    self.stop()
                }
            })
            .store(in: &subscribers)
    }
    
    func start() {
        fileWatcher?.start()
    }
    
    func stop() {
        print("stopped")
        fileWatcher?.stop()
    }
    
    deinit {
        stop()
        fileWatcher = nil
    }
}
