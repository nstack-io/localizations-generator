//
//  LocalizationsGenerator.swift
//  nstack-localizations-generator
//
//  Created by Dominik Hádl on 07/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

public enum ErrorCode: Int {
    case wrongArguments = 1000
    case downloaderError
    case parserError
    case generatorError
}

// Public interface/implementation
@objc open class LocalizationsGenerator: NSObject {
    @objc open class func generate(_ arguments: [String]) throws {
        _ = try LGenerator().generate(arguments)
        _ = try SKTGenerator().generate(arguments)
    }
    
//    open class func generateFromData(_ data: Data, _ settings: GeneratorSettings) throws -> (code: String, JSON: [String: AnyObject]) {
//        return try Generator.generateFromData(data, settings, localeId: )
//    }
}

struct LGenerator: Generator {

    func generateMainModelFromParserOutput(_ output: ParserOutput, subModels: String?, settings: GeneratorSettings) throws -> String {
        
        var indent = Indentation(level: 0)

        let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
        let postfix = ": " + (settings.availableFromObjC ? "NSObject, " : "") + "LocalizableModel {\n"
        var modelString = prefix + self.modelName + postfix
        
        indent = indent.nextLevel()

        for key in output.mainKeys {
            if key.hasPrefix("_") { continue } // skip underscored
            modelString += indent.string()
            modelString += "public var \(key.escaped) = \(output.isFlat ? "\"\"" : "\(key.uppercasedFirstLetter)()")"
            modelString += "\n"
        }

        modelString += "\n"
        modelString += indent.string() + "enum CodingKeys: String, CodingKey {\n"
        indent = indent.nextLevel()
        output.mainKeys.forEach({ key in
            if key.hasPrefix("_") { return } // skip underscored
            if key == "defaultSection" {
                modelString += indent.string() + "case defaultSection = \"default\"\n"
            } else {
                modelString += indent.string() + "case \(key)\n"
            }
        })
        indent = indent.previousLevel()
        modelString += indent.string() + "}\n"
        
        // Add empty init
        modelString += "\n"
        modelString += indent.string() + "public override init() { super.init() }\n"
        
        // Add decode
        modelString += "\n"
        modelString += indent.string() + "public required init(from decoder: Decoder) throws {\n"
        indent = indent.nextLevel()
        modelString += indent.string() + "super.init()\n"
        modelString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
        output.mainKeys.forEach({
            if $0.hasPrefix("_") { return } // skip underscored
            modelString += indent.string() + "\($0.escaped) = try container.decodeIfPresent(\($0.uppercasedFirstLetter).self, forKey: .\($0)) ?? \($0.escaped)\n"
        })
        indent = indent.previousLevel()
        modelString += indent.string() + "}\n"
        
        // Add subscript
        modelString += "\n"
        modelString += indent.string() + "public override subscript(key: String) -> LocalizableSection? {\n"
        indent = indent.nextLevel()
        modelString += indent.string() + "switch key {\n"
        output.mainKeys.forEach({
            if $0.hasPrefix("_") { return } // skip underscored
            modelString += indent.string() + "case CodingKeys.\($0).stringValue: return \($0.escaped)\n"
        })
        modelString += indent.string() + "default: return nil\n"
        modelString += indent.string() + "}\n"
        indent = indent.previousLevel()
        modelString += indent.string() + "}"
        
        if let subModels = subModels {
            modelString += subModels + "\n"
        }

        modelString += "}\n\n"

        return modelString
    }

    func generateSubModelsFromParserOutput(_ output: ParserOutput, _ settings: GeneratorSettings) throws -> String {
        var modelsString = ""

        var indent = Indentation(level: 1)

        for case let (key, value as [String: AnyObject]) in output.language {
            let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
            let postfix = (settings.availableFromObjC ? ": NSObject, LocalizableSection" : ": LocalizableSection") + " {\n"
            var subString = "\n\n" + indent.string() + prefix + "\(key.uppercasedFirstLetter.escaped)" + postfix
            
            indent = indent.nextLevel()

            // Add the translation keys for the model
            for subKey in value.keys {
                subString += indent.string()
                subString += "public var \(subKey.escaped) = \"\"\n"
            }

            // RITO - Start
            subString += "\n"
            subString += indent.string() + "enum CodingKeys: String, CodingKey {\n"
            indent = indent.nextLevel()

            for subKey in value.keys {
                if subKey.hasPrefix("_") { continue } // skip underscored
                subString += indent.string() + "case \(subKey)\n"
            }

            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            // RITO - End

            // Add empty init
            subString += "\n"
            subString += indent.string() + "public override init() { super.init() }\n"
            
            // Add decode
            subString += "\n"
            subString += indent.string() + "public required init(from decoder: Decoder) throws {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "super.init()\n"
            subString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"

            value.keys.forEach({
                subString += indent.string() + "\($0.escaped) = try container.decodeIfPresent(String.self, forKey: .\($0)) ?? \"__\($0)\"\n"

            })

            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            // Add subscript
            subString += "\n"
            subString += indent.string() + "public override subscript(key: String) -> String? {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "switch key {\n"
            value.keys.forEach({ subString += indent.string() + "case CodingKeys.\($0).stringValue: return \($0.escaped)\n" })
            subString += indent.string() + "default: return nil\n"
            subString += indent.string() + "}\n"
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            indent = indent.previousLevel()

            subString += indent.string() + "}"
            modelsString += subString
        }

        return modelsString
    }
}
