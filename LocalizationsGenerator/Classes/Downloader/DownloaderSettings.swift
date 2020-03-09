//
//  DownloaderSettings.swift
//  nstack-localizations-generator
//
//  Created by Dominik Hádl on 09/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct DownloaderSettings {
    var localizationsURL: String
    var appID: String?
    var appKey: String?
    var flatTranslations: Bool
    var authorization: String?
    var extraHeaders: [String]?
    var convertFromSnakeCase: Bool
}

extension DownloaderSettings {
    // Default Localization Config URL
    fileprivate static let localizationsURL =  "https://nstack.io/api/v2/content/localize/resources/platforms/mobile"

    // Dictionary keys
    fileprivate static let plistURLKey    = "REST_API_URL"
    fileprivate static let plistAppIDKey  = "APPLICATION_ID"
    fileprivate static let plistAppKeyKey = "REST_API_KEY"
    fileprivate static let plistFlatKey   = "FLAT"
    fileprivate static let plistConvertSnakeCaseKey = "CONVERTSNAKECASE"
    fileprivate static let authorizationKey  = "AUTHORIZATION"
    fileprivate static let extraHeadersKey = "EXTRAHEADERS"

    static func settingsFromConfigurationFile(plistPath: String) throws -> DownloaderSettings {
        let data = try Data(contentsOf: Foundation.URL(fileURLWithPath: plistPath), options: NSData.ReadingOptions(rawValue: 0))
        let plist = try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil)

        guard let dictionary = plist as? [String: AnyObject] else {
            throw NSError(domain: Constants.ErrorDomain.tGenerator.rawValue,
                          code: ErrorCode.downloaderError.rawValue,
                          userInfo: [NSLocalizedDescriptionKey : "Couldn't parse plist into a dictionary."])
        }

        var downloadURL = localizationsURL
        
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
        
        if let customURLString = dictionary[plistURLKey] as? String{
            downloadURL = customURLString
        }

        let flat = dictionary[plistFlatKey] as? Bool
        let snakeCase = dictionary[plistConvertSnakeCaseKey] as? Bool

        if let headers = dictionary[extraHeadersKey] as? [String] {
            extraHeaders = headers
        }
        
        return DownloaderSettings(
            localizationsURL: downloadURL,
            appID: appId,
            appKey: appKey,
            flatTranslations: flat ?? false,
            authorization: auth,
            extraHeaders: extraHeaders,
            convertFromSnakeCase: snakeCase ?? false)
    }

    init(appID: String?, appKey: String?, flatTranslations: Bool, authorization: String?, convertFromSnakeCase: Bool, extraHeaders: [String]?) {
        self.localizationsURL = DownloaderSettings.localizationsURL
        self.appID = appID
        self.appKey = appKey
        self.flatTranslations = flatTranslations
        self.authorization = authorization
        self.convertFromSnakeCase = convertFromSnakeCase
        self.extraHeaders = extraHeaders
    }
}
