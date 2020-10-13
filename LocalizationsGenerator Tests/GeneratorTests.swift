//
//  GeneratorTests.swift
//  LocalizationsGeneratorTests
//
//  Created by Marius Constantinescu on 29/05/2020.
//  Copyright © 2020 Nodes. All rights reserved.
//

@testable import LocalizationsGenerator
import XCTest

class GeneratorTests: XCTestCase {
    // This is using the Taxa api endpoints, to test with your application
    // modify values accordingly
    lazy var settings = GeneratorSettings(plistPath: nil, keys: nil, outputPath: "/Users/andrewlloydnodes/nstack-translations-generator/TranslationsGeneratorTests", flatTranslations: false, convertFromSnakeCase: true, availableFromObjC: false, standalone: true, authorization: nil, extraHeaders: nil, jsonPath: "", jsonLocaleIdentifier: nil)

    func testGenerateLocalizationsWithDefaultSection() {
        guard let jsonData = GeneratorTestsData.jsonWithDefaultString.data(using: .utf8) else {
            XCTFail()
            return
        }

        guard let (code, _) = try? LGenerator().generateFromData(jsonData, settings, localeId: "en-GB") else {
            XCTFail()
            return
        }

        XCTAssertEqual(code, GeneratorTestsData.expectedCodeWithDefault)
    }

    func testGenerateLocalizationsWithNoDefaultSection() {
        guard let jsonData = GeneratorTestsData.jsonWithoutDefaultString.data(using: .utf8) else {
            XCTFail()
            return
        }

        guard let (code, _) = try? LGenerator().generateFromData(jsonData, settings, localeId: "en-GB") else {
            XCTFail()
            return
        }

        XCTAssertEqual(code, GeneratorTestsData.expectedCodeWithoutDefault)
    }
}
