//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia
import MapKit

struct MapFeatureView: View {
    @StateObject private var markerManager = MarkerManager()
    @State private var isCompareActive: Bool = false
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                MapViewController(viewModel: viewModel)
                    .onAppear {
                        viewModel.mode = .feature
                    }
                    .environmentObject(markerManager)
                    .overlay(
                        HStack(alignment: .top) {
                            Button(action: { addMarkers() }) {
                                Text("Add Marker")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            Button(action: { addPolyline() }) {
                                Text("Add Polyline")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            Button(action: { addPolygon() }) {
                                Text("Add Polygon")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            NavigationLink(destination: MapViewController(viewModel: viewModel)
                                .environmentObject(markerManager), isActive: $isCompareActive) {
                                EmptyView()
                            }
                            .hidden()
                            
                            Button(action: { isCompareActive = true }) {
                                Text("Compare Maps")
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 10)
                        }
                        .padding(.horizontal),
                        alignment: .top
                    )
            }
            .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                print("MapFeatureView Selected Country changed to: \(selectedCountry)")
                viewModel.updateMap(selectedCountry: selectedCountry)
            }
        }
        .environmentObject(countrySettings)
    }
    
    func addMarkers() {
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662), // Ho Chi Minh City
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866)  // Hue
        ]
        for location in locations {
            markerManager.mapView = viewModel.mapViewManager.mapView
            markerManager.addMarker(at: location, title: "")
        }
    }
    
    func addPolyline() {
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662), // Ho Chi Minh City
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866)  // Hue
        ]
        for location in locations {
            markerManager.mapView = viewModel.mapViewManager.mapView
            markerManager.addPolyline(at: location)
        }
    }
    
    func addPolygon() {
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662), // Ho Chi Minh City
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866)  // Hue
        ]
        for location in locations {
            markerManager.mapView = viewModel.mapViewManager.mapView
            markerManager.addPolygon(at: location)
        }
    }
}
