//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia

struct MapAnimationView: View {
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        NavigationView {
            MapViewController(viewModel: viewModel)
                .onAppear {
                    viewModel.prepareForModeChange()
                    viewModel.mode = .animation
                    viewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
                }
                .onDisappear {
                    viewModel.clearMap()
                }
                .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                    print("MapAnimationView Selected Country changed to: \(selectedCountry)")
                    viewModel.updateMap(selectedCountry: selectedCountry)
                }
                .onChange(of: viewModel.isMapReady) { isReady in
                    if isReady {
                        // Map is fully ready, restore any necessary state
                        if let route = viewModel.currentRoute, let coordinates = route.coordinates {
                            if let coordinator = viewModel.mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                                coordinator.animationLineView?.allCoordinates = coordinates
                                coordinator.animationLineView?.addPolyline(to: viewModel.mapViewManager.mapView.style!, mapview: viewModel.mapViewManager.mapView)
                                if viewModel.isAnimating {
                                    coordinator.animationLineView?.animatePolyline()
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Map Animation")
        }
    }
}
