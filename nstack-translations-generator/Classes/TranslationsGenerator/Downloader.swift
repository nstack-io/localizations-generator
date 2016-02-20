//
//  Downloader.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 08/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct Downloader {
    var semaphore = dispatch_semaphore_create(0)

    static func dataWithDownloaderSettings(settings: DownloaderSettings) throws -> NSData? {
        return try Downloader().dataWithDownloaderSettings(settings)
    }

    func dataWithDownloaderSettings(settings: DownloaderSettings) throws -> NSData? {
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

        var actualData: NSData?
        var finalError: ErrorType?

        // Start data task
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
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
                    customError = NSError(domain: Generator.errorDomain, code: ErrorCode.DownloaderError.rawValue,
                        userInfo: [NSLocalizedDescriptionKey : errorString])
                default: break
                }
            }

            actualData = data
            finalError = customError ?? error

            dispatch_semaphore_signal(self.semaphore)
        }.resume()

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

        if let error = finalError {
            throw error
        }

        return actualData
    }
}