//
//  SKGenerator.swift
//  nstack-localizations-generator
//
//  Created by Bob De Kort on 07/08/2019.
//  Copyright © 2019 Nodes. All rights reserved.
//

import Foundation

struct SKTGenerator: Generator {
    
    func writeDataToDisk(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> String {
        
        // 3. - 7. Generate the code
        let generatedOutput = try self.generateFromData(data, settings, localeId: localeId)
        
        // 8. Write to disk (optionally)
        if let outputPath: NSString = settings.outputPath as NSString? {
            let path: NSString   = outputPath.expandingTildeInPath as NSString
            let translationsFile = path.appendingPathComponent(self.modelName + ".swift")
            
            // Save SKTranslations
            try generatedOutput.code.write(toFile: translationsFile, atomically: true, encoding: String.Encoding.utf8)
        }
        
        // 7. Finish
        return generatedOutput.code
    }
    
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
        modelString += indent.string() + "public override init() { super.init() }\n"
        
        // Add decode
        modelString += "\n"
        modelString += indent.string() + "public required init(from decoder: Decoder) throws {\n"
        indent = indent.nextLevel()
        modelString += indent.string() + "super.init()\n"
        modelString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
        output.mainKeys.forEach({
            if $0.hasPrefix("_") { return }
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
        
        for case let (key, value as [String: AnyObject]) in output.language.sorted(by: {$0.0 < $1.0}) {
            let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
            let postfix = (settings.availableFromObjC ? ": NSObject, LocalizableSection " : ": LocalizableSection ") + "{\n"
            var subString = "\n\n" + indent.string() + prefix + "\(key.uppercasedFirstLetter.escaped)" + postfix
            
            indent = indent.nextLevel()
            
            // Add the translation keys for the model
            for subKey in value.keys.sorted(by: {$0 < $1}) {
                subString += indent.string()
                subString += "public var \(subKey.escaped) = \"\"\n"
            }
            
            // RITO - Start
            subString += "\n"
            subString += indent.string() + "enum CodingKeys: String, CodingKey {\n"
            indent = indent.nextLevel()
            
            for subKey in value.keys.sorted(by: {$0 < $1}) {
                if subKey.hasPrefix("_") { continue }
                subString += indent.string() + "case \(subKey)\n"
            }
            
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            // RITO - End
            
            // Add init
            subString += "\n"
            subString += indent.string() + "public override init() {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "super.init()\n"
            for subKey in value.keys.sorted(by: {$0 < $1}) {
                subString += indent.string() + "\(subKey.escaped) = \"\\(classNameLowerCased()).\(subKey.escaped)\"\n"
            }
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            //Add decode
            subString += "\n"
            subString += indent.string() + "public required init(from decoder: Decoder) throws {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "super.init()\n"
            subString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
            value.keys.sorted(by: {$0 < $1}).forEach({
                subString += indent.string() + "\($0.escaped) = try container.decodeIfPresent(String.self, forKey: .\($0)) ?? \"__\($0)\"\n"
            })
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            // Add subscript
            subString += "\n"
            subString += indent.string() + "public override subscript(key: String) -> String? {\n"
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
