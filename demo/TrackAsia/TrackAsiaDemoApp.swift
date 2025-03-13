//
//  TrackAsiaDemoApp.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//

import SwiftUI

@main
struct TrackAsiaDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView().preferredColorScheme(.light)
        }
    }
}
