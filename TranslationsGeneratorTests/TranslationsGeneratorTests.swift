//
//  TranslationsGeneratorTests.swift
//  TranslationsGeneratorTests
//
//  Created by Dominik Hadl on 15/10/2018.
//  Copyright © 2018 Nodes. All rights reserved.
//

import XCTest
@testable import TranslationsGenerator

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
    lazy var settings = GeneratorSettings.init(plistPath: nil, keys: (appID: "63z7NtttDqbYeo51eOxGezBjKzizsKhknRBc", appKey: "245T83h3auiVMGnOaRQ3N7Yagto8oEkD2VvO"), outputPath: "", flatTranslations: false, availableFromObjC: false, standalone: true, authorization: nil, extraHeaders: nil, jsonPath: "", jsonLocaleIdentifier: nil)


    func testGenerate() throws {
        XCTAssertNotNil(settings)
        let dSettings = try settings.downloaderSettings()
        XCTAssertNotNil(dSettings)
        let localisations = try Downloader.localizationsWithDownloaderSettings(dSettings)
        XCTAssertNotNil(localisations)
    }
}
