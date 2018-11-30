//
//  DownloaderSettings.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 09/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct DownloaderSettings {
    var URL: Foundation.URL
    var appID: String?
    var appKey: String?
    var flatTranslations: Bool
    var authorization: String?
    var extraHeaders: [String]?
}

extension DownloaderSettings {
    // Default URL
    fileprivate static let defaultURL = Foundation.URL(string: "https://nstack.io/api/v1/translate/mobile/keys?all=true")!

    // Dictionary keys
    fileprivate static let plistURLKey    = "REST_API_URL"
    fileprivate static let plistAppIDKey  = "APPLICATION_ID"
    fileprivate static let plistAppKeyKey = "REST_API_KEY"
    fileprivate static let plistFlatKey   = "FLAT"
    fileprivate static let authorizationKey  = "AUTHORIZATION"
    fileprivate static let extraHeadersKey = "EXTRAHEADERS"

    static func settingsFromConfigurationFile(plistPath: String) throws -> DownloaderSettings {
        let data = try Data(contentsOf: Foundation.URL(fileURLWithPath: plistPath), options: NSData.ReadingOptions(rawValue: 0))
        let plist = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil)

        guard let dictionary = plist as? [String: AnyObject] else {
            throw NSError(domain: Generator.errorDomain, code: ErrorCode.downloaderError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse plist into a dictionary."])
        }

        var downloadURL = defaultURL
        
        var appId: String?
        var appKey: String?
        var auth: String?
        var extraHeaders: [String]?

        if let identifier = dictionary[plistAppIDKey] as? String, !identifier.isEmpty,
            let key = dictionary[plistAppKeyKey] as? String, !key.isEmpty {
            appId = identifier
            appKey = key
        } else if let authorization = dictionary[authorizationKey] as? String {
            auth = authorization
        }
        
        if let customURLString = dictionary[plistURLKey] as? String, let customURL = Foundation.URL(string: customURLString) {
            downloadURL = customURL
        }

        let flat = dictionary[plistFlatKey] as? Bool

        if let headers = dictionary[extraHeadersKey] as? [String] {
            extraHeaders = headers
        }
        
        return DownloaderSettings(
            URL: downloadURL,
            appID: appId,
            appKey: appKey,
            flatTranslations: flat ?? false,
            authorization: auth,
            extraHeaders: extraHeaders)
    }

    init(appID: String?, appKey: String?, flatTranslations: Bool, authorization: String?, extraHeaders: [String]?) {
        self.URL = DownloaderSettings.defaultURL
        self.appID = appID
        self.appKey = appKey
        self.flatTranslations = flatTranslations
        self.authorization = authorization
        self.extraHeaders = extraHeaders
    }
}
