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

@objc public class TranslationsGenerator: NSObject {
    static let errorDomain = "com.nodes.translations-generator"

    public class func generate(arguments: [String]) throws -> String {

        // 1. Parse arguments
        let settings = try GeneratorSettings.parseFromArguments(arguments)

        // 2. Download translations from API
        let dSettings = try settings.downloaderSettings()
        Downloader.dataWithDownloaderSettings(dSettings) { data, error in
            if let error = error as? NSError {
                print(error.localizedDescription)
                self.finish()
                return
            }

            if let data = data {
                print(data)
            }

            self.finish()
        }

        // 3. Parse translations
        // 4. Generate model code
        // 5. Insert model code into template
        // 6. Write to disk
        // 7. Finish

        return ""
    }

    class func finish() {
        CFRunLoopStop(CFRunLoopGetMain());
    }
}