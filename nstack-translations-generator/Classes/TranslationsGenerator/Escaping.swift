//
//  Escaping.swift
//  TranslationsGenerator
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import Foundation

public enum Escaping {
    public static let reserved: [String] = [
        "class", "break", "as", "associativity", "deinit", "case", "dynamicType", "convenience",
        "enum", "continue", "false", "dynamic", "extension", "default", "is", "didSet", "func",
        "do", "nil", "final", "import", "else", "self", "get", "init", "fallthrough", "Self",
        "infix", "internal", "for", "super", "inout", "let", "if", "true", "lazy", "operator",
        "in", "__COLUMN__", "left", "private", "return", "__FILE__", "mutating", "protocol",
        "switch", "__FUNCTION__", "none", "public", "where", "__LINE__", "nonmutating", "static",
        "while", "optional", "struct", "override", "subscript", "postfix", "typealias",
        "precedence", "var", "prefix", "Protocol", "required", "right", "set", "Type",
        "unowned", "weak"
    ]
}

extension String {
    public var escaped: String {
        return Escaping.reserved.contains(self) ? "`\(self)`" : self
    }
    
    public var unescaped: String {
        return self.replacingOccurrences(of: "`", with: "")
    }
}
