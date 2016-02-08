//
//  Downloader.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 08/02/16.
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
            throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse plist into a dictionary."])
        }

        var downloadURL = defaultURL

        guard let appID = dictionary[plistAppIDKey] as? String, appKey = dictionary[plistAppKeyKey] as? String else {
            throw NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
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

    init(appID: String, appKey: String) {
        self.URL = DownloaderSettings.defaultURL
        self.appID = appID
        self.appKey = appKey
        self.flatTranslations = false
    }
}

struct Downloader {

    static func dataWithDownloaderSettings(settings: DownloaderSettings, completion: ((data: NSData?, error: ErrorType?) -> Void)) {
        var requestURL = settings.URL

        // Add flat if needed
        if settings.flatTranslations, let comps = NSURLComponents(URL: requestURL, resolvingAgainstBaseURL: false) {
            let queryItem = NSURLQueryItem(name: "flat", value: "true")
            comps.queryItems?.append(queryItem)
            requestURL = comps.URL ?? requestURL
        }

        let request = NSMutableURLRequest(URL: requestURL)

        // Add headers
        request.setValue("application/vnd.nodes", forHTTPHeaderField: "accept")
        request.setValue(settings.appKey, forHTTPHeaderField: "X-Rest-Api-Key")
        request.setValue(settings.appID, forHTTPHeaderField: "X-Application-Id")

        // Start data task
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            var customError: NSError?

            if let response = response as? NSHTTPURLResponse {
                switch response.statusCode {
                case 300...999:
                    let content: String?
                    if let data = data {
                        let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [String: AnyObject]
                        content = "\(json ?? [:])"
                    } else {
                        content = nil
                    }

                    let errorString = "Server response contained error: \(content ?? "")"
                    customError = NSError(domain: TranslationsGenerator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
                        userInfo: [NSLocalizedDescriptionKey : errorString])
                default: break
                }
            }

            completion(data: data, error: error ?? customError)
        }

        task.resume()
    }
}