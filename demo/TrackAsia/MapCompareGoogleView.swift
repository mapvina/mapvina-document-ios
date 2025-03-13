//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia
import Alamofire
import Combine
import GoogleMaps
import MapKit

struct MapCompareGoogleView: View {
    @State private var searchText: String = ""
    private var timer: Timer?
    @FocusState private var isTextFieldFocused: Bool
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    @State private var googleMapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.8544),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        VStack {
            GoogleMapView(region: $googleMapRegion)
                .frame(height: 300)
            
            MapViewController(viewModel: viewModel)
                .frame(height: 300)
                .onAppear {
                    viewModel.prepareForModeChange()
                    viewModel.mode = .compare
                    viewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
                }
                .onDisappear {
                    viewModel.clearMap()
                }
        }
        .navigationTitle("Map Comparison")
        .onChange(of: countrySettings.selectedCountry) { selectedCountry in
            print("MapCompareGoogleView Selected Country changed to: \(selectedCountry)")
            viewModel.updateMap(selectedCountry: selectedCountry)
            
            // Update Google Map region when country changes
            let defaultLocation = MapUtils.getLatlng(idCountry: selectedCountry)
            withAnimation(.easeInOut(duration: 0.5)) {
                googleMapRegion.center = CLLocationCoordinate2D(
                    latitude: defaultLocation.latitude,
                    longitude: defaultLocation.longitude
                )
                googleMapRegion.span = MKCoordinateSpan(
                    latitudeDelta: 0.1,
                    longitudeDelta: 0.1
                )
            }
        }
        .onChange(of: viewModel.selectedLocation) { location in
            if let location = location {
                withAnimation(.easeInOut(duration: 0.5)) {
                    googleMapRegion.center = location
                    googleMapRegion.span = MKCoordinateSpan(
                        latitudeDelta: 0.1,
                        longitudeDelta: 0.1
                    )
                }
            }
        }
        .onChange(of: viewModel.isMapReady) { isReady in
            if isReady {
                // Map is fully ready, restore any necessary state
                if let location = viewModel.selectedLocation {
                    viewModel.addMarker(at: location, title: "Selected Location")
                }
            }
        }
    }
}

struct GoogleMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: 12
        )
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        mapView.animate(to: GMSCameraPosition.camera(
            withLatitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: 12
        ))
        CATransaction.commit()
    }
}
