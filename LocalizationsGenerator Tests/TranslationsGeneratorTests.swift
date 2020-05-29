//
//  LocalizationsGeneratorTests.swift
//  LocalizationsGeneratorTests
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import XCTest
@testable import LocalizationsGenerator

class TranslationsGeneratorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    //This is using the Taxa api endpoints, to test with your application
    //modify values accordingly
    lazy var settings = GeneratorSettings.init(plistPath: nil, keys: (appID: "5dSr0geJis6PSTpABBR6zfwGbGZDJ2rJZW90", appKey: "XRiVQholofzxvsqxSfWsS3u8769OYszgrNck"), outputPath: "/Users/andrewlloydnodes/nstack-translations-generator/TranslationsGeneratorTests", flatTranslations: false, convertFromSnakeCase: true, availableFromObjC: false, standalone: true, authorization: nil, extraHeaders: nil, jsonPath: "", jsonLocaleIdentifier: nil)


    func testGenerateLocalizations() throws {
        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)
        XCTAssertNotNil(localisations)
    }

    func testGetTranslationData() throws {
        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)

        let locale = localisations?.first
        XCTAssertNotNil(locale)
        let dData = try Downloader.dataWithDownloaderSettings(dSettings, localization: locale!)
        XCTAssertNotNil(dData)
    }

    //If you want to run this test, make sure Translations.swift is empty,
    //once run succesfully it will create a swift file with a required dependency
    //that this project does not have (TranslationManager)
    func testWriteData() throws {

        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)

        let locale = localisations?.first
        XCTAssertNotNil(locale)
        let dData = try Downloader.dataWithDownloaderSettings(dSettings, localization: locale!)
        XCTAssertNotNil(dData)

        let code = try LGenerator().writeDataToDisk(dData!, settings, localeId: "en-GB")
        XCTAssert(code.count > 0)
    }

    //If you want to run this test, make sure SKTranslations.swift is empty,
    //once run succesfully it will create a swift file with a required dependency
    //that this project does not have (TranslationManager)
    func testWriteSKTData() throws {

        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)

        let locale = localisations?.first
        XCTAssertNotNil(locale)
        let dData = try Downloader.dataWithDownloaderSettings(dSettings, localization: locale!)
        XCTAssertNotNil(dData)

        let code = try SKTGenerator().writeDataToDisk(dData!, settings, localeId: "en-GB")
        XCTAssert(code.count > 0)
    }

    func testPassThroughIsDefaultToFallbackJsons() throws {

        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)

        for locale in localisations ?? [] {
            XCTAssertNotNil(locale)
            let dData = try Downloader.dataWithDownloaderSettings(dSettings, localization: locale)
            XCTAssertNotNil(dData)

            let code = try LGenerator().writeDataToDisk(dData!, settings, localeId: locale.language.locale)
            XCTAssert(code.count > 0)
        }
    }

    func testGenerateLocalizationsWithDefaultSection() {
        let jsonString = """
{
  "data" : {
    "default" : {
      "successKey" : "Success"
    },
    "oneMoreSection" : {
      "soManyKeys" : "AndValues"
    }
  },
  "meta" : {
    "language" : {
      "direction" : "LRM",
      "id" : 11,
      "is_best_fit" : false,
      "is_default" : true,
      "locale" : "en-GB",
      "name" : "English (UK)"
    },
    "platform" : {
      "id" : 24,
      "slug" : "mobile"
    }
  }
}
"""
        guard let jsonData = jsonString.data(using: .utf8) else {
            XCTFail()
            return
        }

        guard let (code, json) = try? LGenerator().generateFromData(jsonData, settings, localeId: "en-GB") else {
            XCTFail()
            return
        }

        let expectedCode = """
// ----------------------------------------------------------------------\n// File generated by NStack Translations Generator.\n//\n// Copyright (c) 2018 Nodes ApS\n//\n// Permission is hereby granted, free of charge, to any person obtaining\n// a copy of this software and associated documentation files (the\n// \"Software\"), to deal in the Software without restriction, including\n// without limitation the rights to use, copy, modify, merge, publish,\n// distribute, sublicense, and/or sell copies of the Software, and to\n// permit persons to whom the Software is furnished to do so, subject to\n// the following conditions:\n//\n// The above copyright notice and this permission notice shall be\n// included in all copies or substantial portions of the Software.\n//\n// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\n// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\n// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\n// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\n// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE\n// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n// ----------------------------------------------------------------------\n\nimport Foundation\nimport LocalizationManager\n\npublic final class Localizations: LocalizableModel {\n    public var oneMoreSection = OneMoreSection()\n    public var defaultSection = DefaultSection()\n\n    enum CodingKeys: String, CodingKey {\n        case oneMoreSection\n        case defaultSection = \"default\"\n    }\n\n    public override init() { super.init() }\n\n    public required init(from decoder: Decoder) throws {\n        super.init()\n        let container = try decoder.container(keyedBy: CodingKeys.self)\n        oneMoreSection = try container.decodeIfPresent(OneMoreSection.self, forKey: .oneMoreSection) ?? oneMoreSection\n        defaultSection = try container.decodeIfPresent(DefaultSection.self, forKey: .defaultSection) ?? defaultSection\n    }\n\n    public override subscript(key: String) -> LocalizableSection? {\n        switch key {\n        case CodingKeys.oneMoreSection.stringValue: return oneMoreSection\n        case CodingKeys.defaultSection.stringValue: return defaultSection\n        default: return nil\n        }\n    }\n\n    public final class OneMoreSection: LocalizableSection {\n        public var soManyKeys = \"\"\n\n        enum CodingKeys: String, CodingKey {\n            case soManyKeys\n        }\n\n        public override init() { super.init() }\n\n        public required init(from decoder: Decoder) throws {\n            super.init()\n            let container = try decoder.container(keyedBy: CodingKeys.self)\n            soManyKeys = try container.decodeIfPresent(String.self, forKey: .soManyKeys) ?? \"__soManyKeys\"\n        }\n\n        public override subscript(key: String) -> String? {\n            switch key {\n            case CodingKeys.soManyKeys.stringValue: return soManyKeys\n            default: return nil\n            }\n        }\n    }\n\n    public final class DefaultSection: LocalizableSection {\n        public var successKey = \"\"\n\n        enum CodingKeys: String, CodingKey {\n            case successKey\n        }\n\n        public override init() { super.init() }\n\n        public required init(from decoder: Decoder) throws {\n            super.init()\n            let container = try decoder.container(keyedBy: CodingKeys.self)\n            successKey = try container.decodeIfPresent(String.self, forKey: .successKey) ?? \"__successKey\"\n        }\n\n        public override subscript(key: String) -> String? {\n            switch key {\n            case CodingKeys.successKey.stringValue: return successKey\n            default: return nil\n            }\n        }\n    }\n}\n\n
"""


        XCTAssertEqual(code, expectedCode)
    }

    func testGenerateLocalizationsWithNoDefaultSection() {
            let jsonString = """
    {
      "data" : {
        "oneMoreSection" : {
          "soManyKeys" : "AndValues"
        }
      },
      "meta" : {
        "language" : {
          "direction" : "LRM",
          "id" : 11,
          "is_best_fit" : false,
          "is_default" : true,
          "locale" : "en-GB",
          "name" : "English (UK)"
        },
        "platform" : {
          "id" : 24,
          "slug" : "mobile"
        }
      }
    }
    """
            guard let jsonData = jsonString.data(using: .utf8) else {
                XCTFail()
                return
            }

            guard let (code, json) = try? LGenerator().generateFromData(jsonData, settings, localeId: "en-GB") else {
                XCTFail()
                return
            }

        let expectedCode = """
// ----------------------------------------------------------------------\n// File generated by NStack Translations Generator.\n//\n// Copyright (c) 2018 Nodes ApS\n//\n// Permission is hereby granted, free of charge, to any person obtaining\n// a copy of this software and associated documentation files (the\n// \"Software\"), to deal in the Software without restriction, including\n// without limitation the rights to use, copy, modify, merge, publish,\n// distribute, sublicense, and/or sell copies of the Software, and to\n// permit persons to whom the Software is furnished to do so, subject to\n// the following conditions:\n//\n// The above copyright notice and this permission notice shall be\n// included in all copies or substantial portions of the Software.\n//\n// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,\n// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF\n// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.\n// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY\n// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,\n// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE\n// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n// ----------------------------------------------------------------------\n\nimport Foundation\nimport LocalizationManager\n\npublic final class Localizations: LocalizableModel {\n    public var oneMoreSection = OneMoreSection()\n\n    enum CodingKeys: String, CodingKey {\n        case oneMoreSection\n    }\n\n    public override init() { super.init() }\n\n    public required init(from decoder: Decoder) throws {\n        super.init()\n        let container = try decoder.container(keyedBy: CodingKeys.self)\n        oneMoreSection = try container.decodeIfPresent(OneMoreSection.self, forKey: .oneMoreSection) ?? oneMoreSection\n    }\n\n    public override subscript(key: String) -> LocalizableSection? {\n        switch key {\n        case CodingKeys.oneMoreSection.stringValue: return oneMoreSection\n        default: return nil\n        }\n    }\n\n    public final class OneMoreSection: LocalizableSection {\n        public var soManyKeys = \"\"\n\n        enum CodingKeys: String, CodingKey {\n            case soManyKeys\n        }\n\n        public override init() { super.init() }\n\n        public required init(from decoder: Decoder) throws {\n            super.init()\n            let container = try decoder.container(keyedBy: CodingKeys.self)\n            soManyKeys = try container.decodeIfPresent(String.self, forKey: .soManyKeys) ?? \"__soManyKeys\"\n        }\n\n        public override subscript(key: String) -> String? {\n            switch key {\n            case CodingKeys.soManyKeys.stringValue: return soManyKeys\n            default: return nil\n            }\n        }\n    }\n}\n\n
"""

            XCTAssertEqual(code, expectedCode)


        }
}
