//
//  TranslationsGenerator.swift
//  nstack-translations-generator
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
@objc open class TranslationsGenerator: NSObject {
    @discardableResult @objc
    open class func generate(_ arguments: [String]) throws {
        _ = try Generator.generate(arguments)
    }
    
//    open class func generateFromData(_ data: Data, _ settings: GeneratorSettings) throws -> (code: String, JSON: [String: AnyObject]) {
//        return try Generator.generateFromData(data, settings, localeId: )
//    }
}

struct Generator {
    static let errorDomain = "com.nodes.translations-generator"
    static let modelName   = "Translations"

    static func generate(_ arguments: [String]) throws {

        // 1. Parse arguments
        let settings = try GeneratorSettings.parseFromArguments(arguments)

        // 2. Download translations from API or load from JSON
        let dData: Data?

        if let jsonPath = settings.jsonPath, let locale = settings.jsonLocaleIdentifier {
            let url = URL(fileURLWithPath: jsonPath)
            dData = try Data(contentsOf: url)

            // If we got data, continue with generation, throw otherwise
            guard let data = dData else {
                throw NSError(domain: errorDomain, code: ErrorCode.generatorError.rawValue, userInfo:
                    [NSLocalizedDescriptionKey : "No data received from downloader."])
            }

            _ = try writeDataToDisk(data, settings, localeId: locale)
        } else {
            let dSettings = try settings.downloaderSettings()
            let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)

            // If we got data, continue with generation, throw otherwise
            guard let locales = localisations else {
                throw NSError(domain: errorDomain, code: ErrorCode.generatorError.rawValue, userInfo:
                    [NSLocalizedDescriptionKey : "No data received from downloader."])
            }

            for locale in locales {
                let dData: Data?
                dData = try Downloader.dataWithDownloaderSettings(dSettings, localization: locale)
                
                // If we got data, continue with generation, throw otherwise
                guard let data = dData else {
                    throw NSError(domain: errorDomain, code: ErrorCode.generatorError.rawValue, userInfo:
                        [NSLocalizedDescriptionKey : "No data received from downloader."])
                }

                _ = try writeDataToDisk(data, settings, localeId: locale.language.locale)
            }
        }
    }

    static func writeDataToDisk(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> String {

        // 3. - 7. Generate the code
        let generatedOutput = try self.generateFromData(data, settings, localeId: localeId)

        // 8. Write to disk (optionally)
        if let outputPath: NSString = settings.outputPath as NSString? {
            let path: NSString   = outputPath.expandingTildeInPath as NSString
            let jsonFile         = path.appendingPathComponent(self.modelName + "_\(localeId)" + ".json")
            let translationsFile = path.appendingPathComponent(self.modelName + ".swift")

            // Save translations
            try generatedOutput.code.write(toFile: translationsFile, atomically: true, encoding: String.Encoding.utf8)

            // Save json
            let jsonData = try JSONSerialization.data(withJSONObject: generatedOutput.JSON,
                                                      options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: URL(fileURLWithPath: jsonFile), options: .atomic)
        }

        // 7. Finish
        return generatedOutput.code
    }

    static func generateFromData(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> (code: String, JSON: [String: AnyObject]) {
        // 3. Parse translations
        let parsed = try Parser.parseResponseData(data)

        // 4. If not flat, generate submodels
        let subModels: String? = !parsed.isFlat ? try self.generateSubModelsFromParserOutput(parsed, settings) : nil

        // 5. Generate main model code
        let mainModel = try self.generateMainModelFromParserOutput(parsed, subModels: subModels, settings: settings)

        // 6. Insert model code into template
        let finalString = try templateString(settings) + mainModel

        return (finalString, parsed.JSON)
    }

    fileprivate static func generateMainModelFromParserOutput(_ output: ParserOutput, subModels: String?, settings: GeneratorSettings) throws -> String {
        var indent = Indentation(level: 0)

        let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
        let postfix = ": " + (settings.availableFromObjC ? "NSObject, " : "") + "Translatable {\n"
        var modelString = prefix + self.modelName + postfix
        var shouldAddDefaultSectionCodingKeys = false
        
        indent = indent.nextLevel()

        for key in output.mainKeys {
            if key.hasPrefix("_") { continue } // skip underscored
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
                if key.hasPrefix("_") { return } // skip underscored
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
        
        // Add decode
        modelString += "\n"
        modelString += indent.string() + "public init(from decoder: Decoder) throws {\n"
        indent = indent.nextLevel()
        modelString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
        output.mainKeys.forEach({
            if $0.hasPrefix("_") { return } // skip underscored
            modelString += indent.string() + "\($0.escaped) = try container.decodeIfPresent(\($0.uppercasedFirstLetter).self, forKey: .\($0)) ?? \($0.escaped)\n"
        })
        indent = indent.previousLevel()
        modelString += indent.string() + "}"
        
        // Add subscript
        modelString += "\n"
        modelString += indent.string() + "public subscript(key: String) -> TranslatableSection? {\n"
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

    fileprivate static func generateSubModelsFromParserOutput(_ output: ParserOutput, _ settings: GeneratorSettings) throws -> String {
        var modelsString = ""

        var indent = Indentation(level: 1)

        for case let (key, value as [String: AnyObject]) in output.language {
            let prefix = (settings.availableFromObjC ? "@objc " : "") + "public final class "
            let postfix = (settings.availableFromObjC ? ": NSObject, TranslatableSection" : ": TranslatableSection") + " {\n"
            var subString = "\n\n" + indent.string() + prefix + "\(key.uppercasedFirstLetter.escaped)" + postfix
            
            indent = indent.nextLevel()

            // Add the translation keys for the model
            for subKey in value.keys {
                subString += indent.string()
                subString += "public var \(subKey.escaped) = \"\"\n"
            }
            
            // Add empty init
            subString += "\n"
            subString += indent.string() + "public init() { }\n"
            
            // Add decode
            subString += "\n"
            subString += indent.string() + "public init(from decoder: Decoder) throws {\n"
            indent = indent.nextLevel()
            subString += indent.string() + "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
            value.keys.forEach({
                subString += indent.string() + "\($0.escaped) = try container.decodeIfPresent(String.self, forKey: .\($0)) ?? \"__\($0)\"\n"
            })
            indent = indent.previousLevel()
            subString += indent.string() + "}\n"
            
            // Add subscript
            subString += "\n"
            subString += indent.string() + "public subscript(key: String) -> String? {\n"
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

    fileprivate static func templateString(_ settings: GeneratorSettings) throws -> String {
        let name = "ImplementationTemplate" + (settings.standalone ? "Standalone" : "")
        let templatePath = Bundle(for: TranslationsGenerator.self).path(forResource: name, ofType: "txt")
        guard let path = templatePath else {
            throw NSError(domain: self.errorDomain, code: ErrorCode.generatorError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Internal inconsistency error. Couldn't find template file to insert generated code into."])
        }
        
        let string = try String(contentsOfFile: path)
        
        guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return string.replacingOccurrences(of: " v#VERSION#", with: "")
        }

        return string.replacingOccurrences(of: "#VERSION#", with: versionString)
    }
}
