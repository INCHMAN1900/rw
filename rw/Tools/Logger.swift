//
//  Logger.swift
//  rw
//
//  Created by Asia Fu on 2024/10/20.
//

import Foundation

class Logger {
    private var name: String
    
    init(name: String) {
        self.name = name
    }
    
    public func log(_ items: Any...) {
        print("\(name):", items.map({ "\($0)" }).joined())
    }
}
