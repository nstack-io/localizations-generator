//
//  Language.swift
//  TranslationsGenerator
//
//  Created by Andrew Lloyd on 05/07/2019.
//  Copyright © 2019 Nodes. All rights reserved.
//

import Foundation

public struct Language: Codable {
    public let name: String
    public let locale: String
    public let direction: String
    public let isDefault: Bool
    public let isBestFit: Bool


    enum CodingKeys: String, CodingKey {
        case name, locale, direction
        case isBestFit = "is_best_fit"
        case isDefault = "is_default"
    }
}
