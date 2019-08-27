//
//  Generator.swift
//  nstack-translations-generator
//
//  Created by Bob De Kort on 08/08/2019.
//  Copyright © 2019 Nodes. All rights reserved.
//

import Foundation

protocol Generator {
    var errorDomain: String { get }
    var modelName: String { get }
    
    func generate(_ arguments: [String]) throws
    func writeDataToDisk(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> String
    func generateFromData(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> (code: String, JSON: [String: AnyObject])
    func generateMainModelFromParserOutput(_ output: ParserOutput, subModels: String?, settings: GeneratorSettings) throws -> String
    func generateSubModelsFromParserOutput(_ output: ParserOutput, _ settings: GeneratorSettings) throws -> String
    func templateString(_ settings: GeneratorSettings) throws -> String
}

extension Generator {
    var errorDomain: String {
        return Constants.errorDomainFor(self)
    }
    var modelName: String {
        return Constants.modelNameFor(self)
    }
    
    func generate(_ arguments: [String]) throws {
        
        // 1. Parse arguments
        let settings = try GeneratorSettings.parseFromArguments(arguments)
        
        // 2. Download localizations from API or load from JSON
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
    
    func writeDataToDisk(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> String {
        
        // 3. - 7. Generate the code
        let generatedOutput = try self.generateFromData(data, settings, localeId: localeId)
        
        // 8. Write to disk (optionally)
        if let outputPath: NSString = settings.outputPath as NSString? {
            let path: NSString   = outputPath.expandingTildeInPath as NSString
            let jsonFile         = path.appendingPathComponent(self.modelName + "_\(localeId)" + ".json")
            let localizationsFile = path.appendingPathComponent(self.modelName + ".swift")
            
            // Save localizations
            try generatedOutput.code.write(toFile: localizationsFile, atomically: true, encoding: String.Encoding.utf8)
            
            // Save json
            let jsonData = try JSONSerialization.data(withJSONObject: generatedOutput.JSON,
                                                      options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: URL(fileURLWithPath: jsonFile), options: .atomic)
        }
        
        // 7. Finish
        return generatedOutput.code
    }
    
    func generateFromData(_ data: Data, _ settings: GeneratorSettings, localeId: String) throws -> (code: String, JSON: [String: AnyObject]) {
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
    
    func templateString(_ settings: GeneratorSettings) throws -> String {

        var name = "ImplementationTemplate" + (settings.standalone ? "Standalone" : "")
        //for the SKTGenerator we always want standalone
        if self is SKTGenerator {
            name = "SKTImplementationTemplate"
        }

        let templatePath = Bundle(for: LocalizationsGenerator.self).path(forResource: name, ofType: "txt")
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
