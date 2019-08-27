//
//  TranslationsGeneratorTests.swift
//  TranslationsGeneratorTests
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import XCTest
@testable import LocalizationsGenerator

class LocalizationsGeneratorTests: XCTestCase {

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
    lazy var settings = GeneratorSettings.init(plistPath: nil, keys: (appID: "5dSr0geJis6PSTpABBR6zfwGbGZDJ2rJZW90", appKey: "XRiVQholofzxvsqxSfWsS3u8769OYszgrNck"), outputPath: "/Users/andrewlloydnodes/nstack-localizations-generator/LocalizationsGeneratorTests", flatLocalizations: false, availableFromObjC: false, standalone: true, authorization: nil, extraHeaders: nil, jsonPath: "", jsonLocaleIdentifier: nil)


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

        let code = try TGenerator().writeDataToDisk(dData!, settings, localeId: "en-GB")
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

            let code = try TGenerator().writeDataToDisk(dData!, settings, localeId: locale.language.locale)
            XCTAssert(code.count > 0)
        }
    }
}
