//
//  Parser.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 14/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct ParserOutput {
    var JSON: [String: AnyObject]
    var mainKeys: [String]
    var language: [String: AnyObject]
    var isFlat: Bool
}

struct Parser {
    static func parseResponseData(_ data: Data) throws -> ParserOutput {
        let object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
        guard let dictionary = object as? [String: AnyObject] else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.parserError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "The data isn't in the correct format. Translations JSON file should have a dictionary as it's root object."])
        }

        var content: [String: AnyObject]? = dictionary
        content = content?["data"] as? [String : AnyObject] ?? content
        if let t = content?["Translation"] as? [String : AnyObject] {
            content = t
        } else if let t = content?["translations"] as? [String : AnyObject] {
            content = t
        }
        
        guard let langsDictionary = content, let first = langsDictionary.first else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.parserError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "Parsed JSON wasn't containing translations data."])
        }

        // Check if key is either "en" or "en-UK"
        let isPossibleLanguageKey = first.key.count == 2 || (first.key.count == 5 && first.key.contains("-"))
        let testKey = first.key[first.key.startIndex..<first.key.index(first.key.startIndex, offsetBy: 2)] // substring 0..2
        let isWrappedInLanguages = isPossibleLanguageKey && Locale.isoLanguageCodes.contains(String(testKey))
        
        var language: [String: AnyObject]
        
        if isWrappedInLanguages, let val = first.value as? [String: AnyObject] {
            // the nested lang is value
            language = val
        } else {
            // the root obj is the translations
            language = langsDictionary
        }

        // Fix for default
        if let object = language["default"] {
            language.removeValue(forKey: "default")
            language["defaultSection"] = object
        }

        return ParserOutput(JSON: dictionary, mainKeys: language.map({ return $0.0 }),
                            language: language, isFlat: language is [String: String])
    }
}
