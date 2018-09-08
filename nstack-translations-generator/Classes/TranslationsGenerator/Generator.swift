//
//  TranslationsGenerator.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 07/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation
import ModelGenerator

public enum ErrorCode: Int {
    case wrongArguments = 1000
    case downloaderError
    case parserError
    case generatorError
}

// Public interface/implementation
@objc open class TranslationsGenerator: NSObject {
    @discardableResult @objc
    open class func generate(_ arguments: [String]) throws -> String {
        return try Generator.generate(arguments)
    }
}

struct Generator {
    static let errorDomain = "com.nodes.translations-generator"
    static let modelName   = "Translations"
    static var generatorSettings: ModelGeneratorSettings {
        var settings = ModelGeneratorSettings()
        settings.noConvertCamelCase = true
        return settings
    }

    static func generate(_ arguments: [String]) throws -> String {

        // 1. Parse arguments
        let settings = try GeneratorSettings.parseFromArguments(arguments)

        // 2. Download translations from API
        let dSettings = try settings.downloaderSettings()
        let dData     = try Downloader.dataWithDownloaderSettings(dSettings)

        // If we got data, continue with generation, throw otherwise
        guard let data = dData else {
            throw NSError(domain: errorDomain, code: ErrorCode.generatorError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "No data received from downloader."])
        }

        // 3. - 7. Generate the code
        let generatedOutput = try self.generateFromData(data, settings)

        // 8. Write to disk (optionally)
        if let outputPath: NSString = settings.outputPath as NSString? {
            let path: NSString   = outputPath.expandingTildeInPath as NSString
            let jsonFile         = path.appendingPathComponent(self.modelName + ".json")
            let translationsFile = path.appendingPathComponent(self.modelName + ".swift")

            // Save translations
            try generatedOutput.code.write(toFile: translationsFile, atomically: true, encoding: String.Encoding.utf8)

            // Save json
            let jsonData = try JSONSerialization.data(withJSONObject: generatedOutput.JSON, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: jsonFile), options: .atomic)
        }

        // 7. Finish
        return generatedOutput.code
    }

    static func generateFromData(_ data: Data, _ settings: GeneratorSettings) throws -> (code: String, JSON: [String: AnyObject]) {
        // 3. Parse translations
        let parsed = try Parser.parseResponseData(data)

        // 4. If not flat, generate submodels
        let subModels: (models: String, extensions: String)? = !parsed.isFlat ? try self.generateSubModelsFromParserOutput(parsed, settings) : nil

        // 5. Generate main model code
        var mainModel = try self.generateMainModelFromParserOutput(parsed, subModels: subModels?.models, settings: settings)

        // 6. Append submodels, if existent
        mainModel += subModels?.extensions ?? ""

        // 7. Insert model code into template
        let finalString = try templateString() + mainModel

        return (finalString, parsed.JSON)
    }

    fileprivate static func generateMainModelFromParserOutput(_ output: ParserOutput, subModels: String?, settings: GeneratorSettings) throws -> String {
        var indent = Indentation(level: 0)

        let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
        let postfix = " : " + (settings.availableFromObjC ? "NSObject, " : "") + "Translatable {\n"
        var modelString = prefix + self.modelName + postfix
        
        indent = indent.nextLevel()

        for key in output.mainKeys {
            modelString += indent.string()
            modelString += "var \(key.escaped) = \(output.isFlat ? "\"\"" : "\(key.uppercasedFirstLetter)()")"
            if key == "defaultSection" { modelString += " //<-default" }
            modelString += "\n"
        }

        indent = indent.previousLevel()

        let extensionString = try ModelGenerator.modelCode(fromSourceCode: modelString + "}", withSettings: self.generatorSettings)

        if let subModels = subModels {
            modelString += subModels + "\n"
        }

        modelString += "}\n\n"
        modelString += extensionString + "\n\n"

        return modelString
    }

    fileprivate static func generateSubModelsFromParserOutput(_ output: ParserOutput, _ settings: GeneratorSettings) throws -> (models: String, extensions: String) {
        var modelsString = ""
        var extensionsString = ""

        var indent = Indentation(level: 1)

        for case let (key, value as [String: AnyObject]) in output.language {
            
            
            let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
            let postfix = (settings.availableFromObjC ? " : NSObject" : "") + " {\n"
            var subString = "\n\n" + indent.string() + prefix + "\(key.uppercasedFirstLetter.escaped)" + postfix
            
            indent = indent.nextLevel()

            // Add the translation keys for the model
            for subKey in value.keys {
                subString += indent.string()
                subString += "var \(subKey.escaped) = \"\"\n"
            }

            indent = indent.previousLevel()

            subString += indent.string() + "}"
            modelsString += subString

            // Generate Serpent extensions
            var settings = self.generatorSettings
            settings.noConvertCamelCase = true
            settings.moduleName = self.modelName

            extensionsString += "\n\n"
            extensionsString += try ModelGenerator.modelCode(fromSourceCode: subString, withSettings: settings)
        }

        return (modelsString, extensionsString)
    }

    fileprivate static func templateString() throws -> String {
        let templatePath = Bundle(for: TranslationsGenerator.self).path(forResource: "ImplementationTemplate", ofType: "txt")
        guard let path = templatePath else {
            throw NSError(domain: self.errorDomain, code: ErrorCode.generatorError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Internal inconsistency error. Couldn't find template file to insert generated code into."])
        }
        
        var string = try String(contentsOfFile: path)
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        string = string.replacingOccurrences(of: "#DATE#", with: dateString)
        
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return string.replacingOccurrences(of: " v#VERSION#", with: "")
        }

        return string.replacingOccurrences(of: "#VERSION#", with: versionString)
    }
}
