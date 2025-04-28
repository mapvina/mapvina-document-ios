//
//  ContentView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import MapKit
import TrackAsia
import Combine
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import UIKit

// MARK: - Toast
struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let duration: Double
}

// MARK: - ContentViewCountrySettings
class ContentViewCountrySettings: ObservableObject {
    @Published var selectedCountry: String = "vn"
    
    var styleURL: String {
        return MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
    }
    
    var location: CLLocationCoordinate2D {
        let latlng = MapUtils.getLatlng(idCountry: selectedCountry)
        return CLLocationCoordinate2D(latitude: latlng.latitude, longitude: latlng.longitude)
    }
    
    var zoomLevel: Double {
        return MapUtils.zoom(idCountry: selectedCountry)
    }
}

// MARK: - ContentView
struct ContentView: View {
    // MARK: - Properties
    @StateObject private var countrySettings = ContentViewCountrySettings()
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var viewModel: ContentViewModel
    
    @State private var currentTab = 0
    @State private var screenTitle = "Single Point"
    @State private var countries: [String: String] = [
        "vn": "Việt Nam",
        "sg": "Singapore",
        "th": "Thailand"
    ]
    @State private var isLoading = false
    @State private var currentToast: Toast?
    
    // MARK: - Initializers
    init() {
        let viewModel = ContentViewModel()
        self._mapViewModel = ObservedObject(wrappedValue: MapViewModel())
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    init(mapViewModel: MapViewModel) {
        let viewModel = ContentViewModel()
        self._mapViewModel = ObservedObject(wrappedValue: mapViewModel)
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Bar
                TopBarView(
                    screenTitle: $screenTitle,
                    selectedCountry: $countrySettings.selectedCountry,
                    countries: countries,
                    onCountrySelected: handleCountrySelection
                )
                
                // Map Content
                ZStack {
                    // Single MapContainer that is reused for all tabs
                    MapContainer(
                        currentTab: $currentTab,
                        mapViewModel: mapViewModel,
                        countrySettings: countrySettings,
                        isLoading: $isLoading
                    )
                    .id("mapView-\(countrySettings.selectedCountry)")
                    .onAppear {
                        prepareMapForInitialMode()
                    }
                    
                    // Overlay for the current tab
                    overlayForCurrentTab
                    
                    // Loading overlay
                    if isLoading {
                        Color.white.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("colorBlue")))
                    }
                }
                
                // Bottom Bar
                BottomBarView(selectedTab: $currentTab.onChange { newValue in
                    handleTabSelection(newValue)
                })
            }
            .onChange(of: countrySettings.selectedCountry) { newValue in
                handleCountryChange(newValue)
            }
            
            // Toast message
            if let toast = currentToast {
                VStack {
                    Spacer()
                    Text(toast.message)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: currentToast != nil)
                .zIndex(100) // Ensure it displays above all other elements
            }
        }
        .environmentObject(viewModel)
    }
    
    // MARK: - Helper Methods
    
    func showToast(_ message: String, duration: Double = 3.0) {
        DispatchQueue.main.async {
            self.currentToast = Toast(message: message, duration: duration)
            
            // Automatically hide toast after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation {
                    self.currentToast = nil
                }
            }
        }
    }
    
    private func prepareMapForInitialMode() {
        // Set default mode
        mapViewModel.updateMode(.singlePoint)
        
        // Set default country from UserDefaults or use Vietnam if none
        if UserDefaults.standard.string(forKey: "selectedCountry") == nil {
            UserDefaults.standard.set("vn", forKey: "selectedCountry")
        }
        
        countrySettings.selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") ?? "vn"
        
        // Update map with selected country
        mapViewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
    }
    
    private func handleCountrySelection(_ country: String) {
        // Avoid updating if country hasn't changed
        if countrySettings.selectedCountry == country {
            return
        }
        
        // Show loading
        isLoading = true
        
        // Save to UserDefaults
        UserDefaults.standard.set(country, forKey: "selectedCountry")
        
        // Update state
        DispatchQueue.main.async {
            countrySettings.selectedCountry = country
        }
    }
    
    private func handleCountryChange(_ country: String) {
        DispatchQueue.main.async {
            // Update map with new country
            mapViewModel.updateMap(selectedCountry: country)
            
            // Hide loading after map has updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
    
    private func handleTabSelection(_ tab: Int) {
        // Do nothing if already on the correct tab
        if currentTab == tab {
            return
        }
        
        // Show loading
        isLoading = true
        
        // Update screen title based on selected tab
        updateScreenTitle(for: tab)
        
        // Update mapViewModel mode
        DispatchQueue.main.async {
            // Update current tab
            currentTab = tab
            
            // Use updateMode method in MapViewModel
            // This will automatically handle mode switching and map cleanup/initialization
            switch tab {
            case 0:
                mapViewModel.updateMode(.singlePoint)
            case 1:
                mapViewModel.updateMode(.wayPoint)
            case 2:
                mapViewModel.updateMode(.cluster)
            case 3:
                mapViewModel.updateMode(.animation)
            case 4:
                mapViewModel.updateMode(.feature)
            default:
                break
            }
            
            // Hide loading after mode has been updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
    
    private func updateScreenTitle(for tab: Int) {
        switch tab {
        case 0:
            screenTitle = "Single Point"
        case 1:
            screenTitle = "Waypoints"
        case 2:
            screenTitle = "Clusters"
        case 3:
            screenTitle = "Animation"
        case 4:
            screenTitle = "Features"
        default:
            screenTitle = "TrackAsia"
        }
    }
    
    // MARK: - ContentViewModel
    class ContentViewModel: ObservableObject {
        func showToast(_ message: String, duration: Double = 3.0) {
            // Redirect method call to ContentView
            DispatchQueue.main.async {
                if let window = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first?.windows
                    .first, 
                   let rootViewController = window.rootViewController {
                    
                    // Find ContentView through UIHostingController
                    var currentController: UIViewController? = rootViewController
                    while currentController != nil {
                        if let hostingController = currentController as? UIHostingController<ContentView> {
                            // Call ContentView's showToast method
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
    
    // MARK: - Tab Overlay Views
    
    @ViewBuilder
    private var overlayForCurrentTab: some View {
        switch currentTab {
        case 0:
            MapSinglePointView(mapViewModel: mapViewModel)
        case 1:
            MapWayPointView(mapViewModel: mapViewModel)
        case 2:
            MapClusterView(mapViewModel: mapViewModel)
        case 3:
            MapAnimationView(mapViewModel: mapViewModel)
        case 4:
            MapFeatureView(mapViewModel: mapViewModel)
        default:
            EmptyView()
        }
    }
}

// MARK: - Helper Extension
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
} 