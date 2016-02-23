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
    case WrongArguments = 1000
    case DownloaderError
    case ParserError
    case GeneratorError
}

// Public interface/implementation
@objc public class TranslationsGenerator: NSObject {
    public class func generate(arguments: [String]) throws -> String {
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

    static func generate(arguments: [String]) throws -> String {

        // 1. Parse arguments
        let settings = try GeneratorSettings.parseFromArguments(arguments)

        // 2. Download translations from API
        let dSettings = try settings.downloaderSettings()
        let dData     = try Downloader.dataWithDownloaderSettings(dSettings)

        // If we got data, continue with generation, throw otherwise
        guard let data = dData else {
            throw NSError(domain: errorDomain, code: ErrorCode.GeneratorError.rawValue, userInfo:
                [NSLocalizedDescriptionKey : "No data received from downloader."])
        }

        // 3. - 7. Generate the code
        let generatedOutput = try self.generateFromData(data)

        // 8. Write to disk (optionally)
        if let outputPath: NSString = settings.outputPath {
            let path: NSString   = outputPath.stringByExpandingTildeInPath
            let jsonFile         = path.stringByAppendingPathComponent(self.modelName + ".json")
            let translationsFile = path.stringByAppendingPathComponent(self.modelName + ".swift")

            // Save translations
            try generatedOutput.code.writeToFile(translationsFile, atomically: true, encoding: NSUTF8StringEncoding)

            // Save json
            let jsonData = try NSJSONSerialization.dataWithJSONObject(generatedOutput.JSON, options: .PrettyPrinted)
            try jsonData.writeToFile(jsonFile, options: .DataWritingAtomic)
        }

        // 7. Finish
        return generatedOutput.code
    }

    static func generateFromData(data: NSData) throws -> (code: String, JSON: [String: AnyObject]) {
        // 3. Parse translations
        let parsed = try Parser.parseResponseData(data)

        // 4. If not flat, generate submodels
        let subModels: (models: String, extensions: String)? = !parsed.isFlat ? try self.generateSubModelsFromParserOutput(parsed) : nil

        // 5. Generate main model code
        var mainModel = try self.generateMainModelFromParserOutput(parsed, subModels: subModels?.models)

        // 6. Append submodels, if existent
        mainModel += subModels?.extensions ?? ""

        // 7. Insert model code into template
        let finalString = try templateString() + mainModel

        return (finalString, parsed.JSON)
    }

    private static func generateMainModelFromParserOutput(output: ParserOutput, subModels: String?) throws -> String {
        var indent = Indentation(level: 0)

        var modelString = "public struct \(self.modelName): Translatable {\n"

        indent = indent.nextLevel()

        for key in output.mainKeys {
            modelString += indent.string()
            modelString += "var \(key) = \(output.isFlat ? "\"\"" : "\(key.uppercasedFirstLetter)()")"
            if key == "defaultSection" { modelString += " //<-default" }
            modelString += "\n"
        }

        indent = indent.previousLevel()

        let extensionString = try ModelGenerator.modelCodeFromSourceCode(modelString + "}", withSettings: self.generatorSettings)

        if let subModels = subModels {
            modelString += subModels + "\n"
        }

        modelString += "}\n\n"
        modelString += extensionString + "\n\n"

        return modelString
    }

    private static func generateSubModelsFromParserOutput(output: ParserOutput) throws -> (models: String, extensions: String) {
        var modelsString = ""
        var extensionsString = ""

        var indent = Indentation(level: 1)

        for case let (key, value as [String: AnyObject]) in output.language {
            var subString = "\n\n" + indent.string() + "public struct \(key.uppercasedFirstLetter) {\n"

            indent = indent.nextLevel()

            // Add the translation keys for the model
            for subKey in value.keys {
                subString += indent.string()
                subString += "var \(subKey) = \"\"\n"
            }

            indent = indent.previousLevel()

            subString += indent.string() + "}"
            modelsString += subString

            // Generate Serializable extensions
            var settings = self.generatorSettings
            settings.noConvertCamelCase = true
            settings.moduleName = self.modelName

            extensionsString += "\n\n"
            extensionsString += try ModelGenerator.modelCodeFromSourceCode(subString, withSettings: settings)
        }

        return (modelsString, extensionsString)
    }

    private static func templateString() throws -> String {
        let templatePath = NSBundle(forClass: TranslationsGenerator.self).pathForResource("ImplementationTemplate", ofType: "txt")
        guard let path = templatePath else {
            throw NSError(domain: self.errorDomain, code: ErrorCode.GeneratorError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Internal inconsistency error. Couldn't find template file to insert generated code into."])
        }

        var string = try String(contentsOfFile: path)
        let dateString = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .LongStyle)
        string = string.stringByReplacingOccurrencesOfString("#DATE#", withString: dateString)

        return string
    }
}
