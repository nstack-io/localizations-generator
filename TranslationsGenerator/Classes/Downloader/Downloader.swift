//
//  Downloader.swift
//  nstack-translations-generator
//
//  Created by Dominik Hádl on 08/02/16.
//  Copyright © 2016 Nodes. All rights reserved.
//

import Foundation

struct Downloader {
    var semaphore = DispatchSemaphore(value: 0)

    static func dataWithDownloaderSettings(_ settings: DownloaderSettings) throws -> Data? {
        return try Downloader().dataWithDownloaderSettings(settings)
    }

    func dataWithDownloaderSettings(_ settings: DownloaderSettings) throws -> Data? {
        var requestURL = settings.URL

        // Add flat if needed
        if settings.flatTranslations, var comps = URLComponents(url: requestURL as URL, resolvingAgainstBaseURL: false) {
            let queryItem = URLQueryItem(name: "flat", value: "true")
            comps.queryItems?.append(queryItem)
            requestURL = comps.url as URL? ?? requestURL
        }

        let request = NSMutableURLRequest(url: requestURL as URL)

        // Add headers
        request.setValue(settings.appID, forHTTPHeaderField: "X-Application-Id")
        request.setValue(settings.appKey, forHTTPHeaderField: "X-Rest-Api-Key")
        
        var versionString = "1.0"
        if let bundleVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            versionString = bundleVersionString
        }

        request.setValue("ios;nstack-translations-generator;\(versionString);macOS;mac", forHTTPHeaderField: "n-meta")
        
        var actualData: Data?
        var finalError: Error?

        // Start data task
        URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
            var customError: NSError?

            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 300...999:
                    let content: String?
                    if let data = data {
                        let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                        let json = object as? [String: AnyObject]
                        content = "\(json ?? [:])"
                    } else {
                        content = nil
                    }

                    let errorString = "Server response contained error: \(content ?? "")"
                    customError = NSError(domain: Generator.errorDomain, code: ErrorCode.downloaderError.rawValue,
                        userInfo: [NSLocalizedDescriptionKey : errorString])
                default: break
                }
            }

            actualData = data
            finalError = customError ?? error

            self.semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        if let error = finalError {
            throw error
        }

        return actualData
    }
}
