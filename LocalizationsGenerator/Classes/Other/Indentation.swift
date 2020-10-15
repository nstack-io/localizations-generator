//
//  Indentation.swift
//  LocalizationsGenerator
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import Foundation

public struct Indentation {
    public static let defaultString = String(repeating: " ", count: 4)
    
    public let level: Int
    public let customString: String?
    
    public init(level: Int) {
        self.level = level
        self.customString = nil
    }
    
    public init(level: Int, customString: String?) {
        self.level = level
        self.customString = customString
    }
}

public extension Indentation {
    func string() -> String {
        var string = ""
        let indent = (customString ?? Indentation.defaultString)
        
        for _ in 0..<level {
            string += indent
        }
        
        return string
    }
}

public extension Indentation {
    func nextLevel() -> Indentation {
        return Indentation(level: level + 1, customString: customString)
    }
    
    func previousLevel() -> Indentation {
        return Indentation(level: level > 0 ? level - 1 : 0, customString: customString)
    }
}
