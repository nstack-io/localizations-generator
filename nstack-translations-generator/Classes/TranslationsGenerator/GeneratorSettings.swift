//
//  GeneratorSettings.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 08/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct GeneratorSettings {
    var plistPath: String?
    var keys: [String]?
    var outputPath: String
}

extension GeneratorSettings {
    static func parseFromArguments(arguments: [String]) throws -> GeneratorSettings {
        if arguments.count < 5 || arguments.count > 8 {
            throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.WrongArguments.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Error, wrong number of arguments passed."])
        }

        // Parse arguments
        var lastKey = ""
        var parsedArguments = [String: [String]]()
        for arg in arguments {
            if arg.hasPrefix("-") {
                parsedArguments[arg] = []
                lastKey = arg
            } else {
                parsedArguments[lastKey]?.append(arg)
            }
        }

        // Validate arguments
        guard let outputPaths = parsedArguments["-output"] where outputPaths.count == 1 else {
            throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.WrongArguments.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "No or multiple output paths specified."])
        }

        var plistPath: String?
        var keys: [String]?

        // Get plist path if present
        if let plistPaths = parsedArguments["-plist"] where plistPaths.count == 1 {
            plistPath = plistPaths[0]
        }

        // Get keys if present
        if let keysArray = parsedArguments["-keys"] where keysArray.count == 2 {
            keys = keysArray
        }

        // Check if we have keys
        if plistPath == nil && keys?.count != 2 {
            throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.WrongArguments.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "No or multiple plist paths, or wrong keys format."])
        }

        return GeneratorSettings(plistPath: plistPath, keys: keys, outputPath: outputPaths[0])
    }

    func downloaderSettings() throws -> DownloaderSettings {
        if let keys = keys {
            return DownloaderSettings(appID: keys[0], appKey: keys[2])
        } else if let plistPath = plistPath {
            return try DownloaderSettings.settingsFromConfigurationFile(plistPath: plistPath)
        }
        throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.GeneratorError.rawValue,
            userInfo: [NSLocalizedDescriptionKey : "Couldn't generate downloader settings from arguments."])
    }
}