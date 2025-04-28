//
//  ContentViewModel.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var messageText: String = ""
    
    func showToast(_ message: String, duration: Double = 3.0) {
        // Chuyển lại lời gọi phương thức cho ContentView
        DispatchQueue.main.async {
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .first, 
               let rootViewController = window.rootViewController {
                
                // Tìm ContentView thông qua UIHostingController
                var currentController: UIViewController? = rootViewController
                while currentController != nil {
                    if let hostingController = currentController as? UIHostingController<ContentView> {
                        // Gọi phương thức showToast của ContentView
                        let contentView = hostingController.rootView
                        contentView.showToast(message, duration: duration)
                        break
                    } else if let navigationController = currentController as? UINavigationController {
                        currentController = navigationController.visibleViewController
                    } else if let tabController = currentController as? UITabBarController {
                        currentController = tabController.selectedViewController
                    } else if let presentedController = currentController?.presentedViewController {
                        currentController = presentedController
                    } else {
                        currentController = nil
                    }
                }
            }
        }
    }
} 