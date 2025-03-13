//
//  LocationManager.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 27/12/2023.
//

//import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
            print("Latitude: \(String(describing: userLocation?.coordinate.latitude))")
            print("Longitude: \(String(describing: userLocation?.coordinate.longitude))")
        }
    }
}
