//
//  SKGenerator.swift
//  nstack-translations-generator
//
//  Created by Bob De Kort on 07/08/2019.
//  Copyright © 2019 Nodes. All rights reserved.
//

import Foundation

struct SKTGenerator: Generator {
    
    func generateMainModelFromParserOutput(_ output: ParserOutput, subModels: String?, settings: GeneratorSettings) throws -> String {
        
        var indent = Indentation(level: 0)
        let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
        let postFix = ": " + (settings.availableFromObjC ? "NSObject, " : "") + "LocalizableModel {\n"
        var modelString = prefix + self.modelName + postFix
        
        var shouldAddDefaultSectionCodingKeys = false
        
        indent = indent.nextLevel()
        
        for key in output.mainKeys {
            if key.hasPrefix("_") { continue }
            modelString += indent.string()
            modelString += "public var \(key.escaped) = \(output.isFlat ? "\"\"" : "\(key.uppercasedFirstLetter)()")"
            if key == "defaultSection" { shouldAddDefaultSectionCodingKeys = true }
            modelString += "\n"
        }
        
        if shouldAddDefaultSectionCodingKeys {
            modelString += "\n"
            modelString += indent.string() + "enum CodingKeys: String, CodingKey {\n"
            indent = indent.nextLevel()
            output.mainKeys.forEach({ key in
                if key.hasPrefix("_") { return }
                if key == "defaultSection" {
                    modelString += indent.string() + "case defaultSection = \"default\"\n"
                } else {
                    modelString += indent.string() + "case \(key)\n"
                }
            })
            indent = indent.previousLevel()
            modelString += indent.string() + "}\n"
        }
        
        // Add empty init
        modelString += "\n"
        modelString += indent.string() + "public init() { }\n"
        
        // Add subscript
        modelString += "\n"
        modelString += indent.string() + "public subscript(key: String) -> LocalizableSection? {\n"
        indent = indent.nextLevel()
        modelString += indent.string() + "switch key {\n"
        output.mainKeys.forEach({
            if $0.hasPrefix("_") { return }
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
            let postfix = (settings.availableFromObjC ? ": NSObject, LocalizableSection " : ": LocalizableSection ") + "{\n"
            var subString = "\n\n" + indent.string() + prefix + "\(key.uppercasedFirstLetter.escaped)" + postfix
            
            indent = indent.nextLevel()
            
            // Add the translation keys for the model
            for subKey in value.keys {
                subString += indent.string()
                subString += "public var \(subKey.escaped) = \"\"\n"
            }
            
            // Add init
            subString += "\n"
            subString += indent.string() + "public init() {\n"
            indent = indent.nextLevel()
            for subKey in value.keys {
                subString += indent.string() + "\(subKey.escaped) = \"\\(classNameLowerCased()).\(subKey.escaped)\"\n"
            }
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            // Add subscript
            subString += "\n"
            subString += indent.string() + "public subscript(key: String) -> String? {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "return \"\"\n"
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            indent = indent.previousLevel()
            subString += indent.string() + "}"
            
            modelsString += subString
        }
        
        return modelsString
    }
}
