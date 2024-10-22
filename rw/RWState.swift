//
//  RWState.swift
//  rw
//
//  Created by Asia Fu on 2024/10/23.
//

import SwiftUI
import Defaults
import LaunchAtLogin

extension Defaults.Keys {
    static let launchAtLogin = Key("rwLaunchAtLogin", default: false)
    static let includes = Key("rwIncludes", default: [URL]())
    static let excludes = Key("rwExcludes", default: [URL]())
}

/// The global state object for app
class RWState: ObservableObject {
    static let global = RWState()
    
    @Published var isRunning = true
    
    var includes = [URL]()
    var excludes = [URL]()
    
    init() {
        self.includes = Defaults[.includes]
        self.excludes = Defaults[.excludes]
    }
}
