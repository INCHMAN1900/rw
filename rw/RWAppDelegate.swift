//
//  RWAppDelegate.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import SwiftUI

class RWAppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: RWMonitor? = nil
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        monitor = RWMonitor()
        monitor?.start()
    }
}
