//
//  ContentViewCountrySettings.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation

class ContentViewCountrySettings: ObservableObject {
    @Published var selectedCountry: String = "vn"
    
    var styleURL: String {
        return MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
    }
    
    var location: CLLocationCoordinate2D {
        var latlng =  MapUtils.getLatlng(idCountry: selectedCountry)
        return CLLocationCoordinate2D(latitude: latlng.latitude, longitude: latlng.longitude)
    }
    
    var zoomLevel: Double {
        return MapUtils.zoom(idCountry: selectedCountry)
    }
} 