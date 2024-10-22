//
//  RWApp.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import SwiftUI

@main
struct RWApp: App {
    @NSApplicationDelegateAdaptor(RWAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RWView()
        }
        
        Settings {
            SettingView()
        }
    }
}
