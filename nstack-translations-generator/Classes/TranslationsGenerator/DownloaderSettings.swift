//
//  DownloaderSettings.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 09/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct DownloaderSettings {
    var URL: NSURL
    var appID: String
    var appKey: String
    var flatTranslations: Bool
}

extension DownloaderSettings {
    // Default URL
    private static let defaultURL = NSURL(string: "https://nstack.io/api/v1/translate/mobile/keys?all=true")!

    // Dictionary keys
    private static let plistURLKey    = "REST_API_URL"
    private static let plistAppIDKey  = "APPLICATION_ID"
    private static let plistAppKeyKey = "REST_API_KEY"
    private static let plistFlatKey   = "FLAT"

    static func settingsFromConfigurationFile(plistPath plistPath: String) throws -> DownloaderSettings {
        let data = try NSData(contentsOfFile: plistPath, options: NSDataReadingOptions(rawValue: 0))
        let plist = try NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil)

        guard let dictionary = plist as? [String: AnyObject] else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse plist into a dictionary."])
        }

        var downloadURL = defaultURL

        guard let appID = dictionary[plistAppIDKey] as? String, appKey = dictionary[plistAppKeyKey] as? String else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "App ID or API key not found in the plist file."])
        }

        if let customURLString = dictionary[plistURLKey] as? String, customURL = NSURL(string: customURLString) {
            downloadURL = customURL
        }

        let flat = dictionary[plistFlatKey] as? Bool

        return DownloaderSettings(
            URL: downloadURL,
            appID: appID,
            appKey: appKey,
            flatTranslations: flat ?? false)
    }

    init(appID: String, appKey: String, flatTranslations: Bool = false) {
        self.URL = DownloaderSettings.defaultURL
        self.appID = appID
        self.appKey = appKey
        self.flatTranslations = flatTranslations
    }
}