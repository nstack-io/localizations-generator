//
//  Extensions.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 20/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

extension String {
    var uppercasedFirstLetter: String {
        return String(prefix(1)).uppercased() + String(dropFirst())
    }
}
