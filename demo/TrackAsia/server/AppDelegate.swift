//
//  AppDelegate.swift
//  TrackAsia
//
//  Created by SangNguyen on 09/01/2024.
//

import Foundation

import UIKit
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyDEYfN5At0Qyp5KCDhBTUaeBxYUqG-gOds")
        return true
    }
}
