//
//  AppDelegate.swift
//  MapVina
//
//  Created by SangNguyen on 09/01/2024.
//

import Foundation
import UIKit
import GoogleMaps
import MapVina

// NSURLProtocol that intercepts MapVina requests and forces HTTP/1.1
// by using NSURLConnection (which doesn't support QUIC)
class HTTP1Protocol: URLProtocol {
    static var propertyKey = "HTTP1ProtocolHandled"

    override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return false }
        guard let host = request.url?.host?.lowercased(),
              host.contains("mapvina.com") else { return false }
        if URLProtocol.property(forKey: propertyKey, in: request) != nil {
            return false
        }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        var newRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: HTTP1Protocol.propertyKey, in: newRequest)

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            var response: URLResponse?
            do {
                let data = try NSURLConnection.sendSynchronousRequest(
                    newRequest as URLRequest,
                    returning: &response
                )
                if let httpResponse = response as? HTTPURLResponse {
                    DispatchQueue.main.async {
                        self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                        self.client?.urlProtocol(self, didLoad: data)
                        self.client?.urlProtocolDidFinishLoading(self)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.client?.urlProtocol(self, didFailWithError: error)
                }
            }
        }
    }

    override func stopLoading() {}
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyDEYfN5At0Qyp5KCDhBTUaeBxYUqG-gOds")

        // Register HTTP1Protocol in MLNNetworkConfiguration to force HTTP/1.1
        // This fixes QUIC/HTTP3 timeout in the iOS simulator
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.httpMaximumConnectionsPerHost = 8
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        sessionConfig.urlCache = nil
        var protocols = sessionConfig.protocolClasses ?? []
        protocols.insert(HTTP1Protocol.self, at: 0)
        sessionConfig.protocolClasses = protocols
        MLNNetworkConfiguration.sharedManager.sessionConfiguration = sessionConfig
        NSLog("AppDelegate: registered HTTP1Protocol in MLNNetworkConfiguration")

        MLNSettings.use(.mapVina)
        MLNSettings.apiKey = "public_key"

        return true
    }
}
