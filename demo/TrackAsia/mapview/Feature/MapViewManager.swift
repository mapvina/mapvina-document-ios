//
//  MapViewManager.swift
//  TrackAsia
//
//  Created by SangNguyen on 19/02/2024.
//

import Foundation
import TrackAsia
import MapboxNavigation

class MapViewManager: ObservableObject {
    @Published var zoomLevelCurrent = 10.0
    @Published var locationDefault = CLLocationCoordinate2D(latitude: 16.455783, longitude: 106.709200)
    @Published var mapView = NavigationMapView(frame: .zero)
    @Published var selectedLocation: (CLLocationCoordinate2D, String?)?
    var onLocationSelectedCallback: ((CLLocationCoordinate2D, String?) -> Void)?
    @Published var is3D = false

    func invokeOnLocationSelected(coordinate: CLLocationCoordinate2D, name: String?) {
        onLocationSelectedCallback?(coordinate, name)
    }

    init() {
        setupMapView()
    }

    private func setupMapView() {
        guard let selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") else {
            return
        }
        let styleUrl = MapUtils.urlStyle(idCountry: selectedCountry, is3D: is3D)
        let location = MapUtils.getLatlng(idCountry: selectedCountry)
        zoomLevelCurrent = MapUtils.zoom(idCountry: selectedCountry)
        locationDefault = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        mapView.styleURL = URL(string: styleUrl)
        mapView.zoomLevel = zoomLevelCurrent
        mapView.centerCoordinate = locationDefault
        mapView.logoView.isHidden = true
        mapView.compassView.isHidden = true
        mapView.showsUserLocation = true
    }

    func addMarker(at coordinate: CLLocationCoordinate2D, title: String?) {
        if(mapView.annotations != nil){
            mapView.removeAnnotations(mapView.annotations!)
        }
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapView.addAnnotation(annotation)
        mapView.setCenter(coordinate, zoomLevel: 8, animated: true)
    }

    func moveCamera(to coordinate: CLLocationCoordinate2D, zoom: Double) {
        mapView.setCenter(coordinate, zoomLevel: zoom, animated: true)
    }

    func centerOnUserLocation() {
        if let userLocation = mapView.userLocation {
            mapView.setCenter(userLocation.coordinate, zoomLevel: 8, animated: true)
        }
    }

    func updateMap(selectedCountry: String) {
        DispatchQueue.main.async {
            let styleUrl = MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
            let location = MapUtils.getLatlng(idCountry: selectedCountry)
            self.zoomLevelCurrent = MapUtils.zoom(idCountry: selectedCountry)
            self.locationDefault = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            self.mapView.centerCoordinate = self.locationDefault
            self.mapView.setCenter(self.locationDefault, zoomLevel: self.zoomLevelCurrent, animated: true)
            print("Updating map with new style URL: \(styleUrl)")
            self.mapView.styleURL = URL(string: styleUrl)
        }
    }
}
