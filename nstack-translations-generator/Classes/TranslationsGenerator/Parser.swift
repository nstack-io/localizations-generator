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
    static func parseResponseData(data: NSData) throws -> ParserOutput {
        let object = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
        guard let dictionary = object as? [String: AnyObject] else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.ParserError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "The data isn't in the correct format. Translations JSON file should have a dictionary as it's root object."])
        }

        var content: [String: AnyObject]? = dictionary
        content = content?["data"] as? [String : AnyObject] ?? content
        if let t = content?["Translation"] as? [String : AnyObject] {
            content = t
        } else if let t = content?["translations"] as? [String : AnyObject] {
            content = t
        }

        guard let langsDictionary = content, firstLanguage = langsDictionary.values.first as? [String: AnyObject] else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.ParserError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "Parsed JSON wasn't containing translations data."])
        }

        // Fix for default
        var language = firstLanguage
        if let object = language["default"] {
            language.removeValueForKey("default")
            language["defaultSection"] = object
        }

        return ParserOutput(JSON: dictionary, mainKeys: language.map({ return $0.0 }), language: language, isFlat: language is [String: String])
    }
}