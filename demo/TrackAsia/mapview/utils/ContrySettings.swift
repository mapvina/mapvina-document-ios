//
//  ContrySettings.swift
//  TrackAsia
//
//  Created by SangNguyen on 19/02/2024.
//

import Foundation
import CoreLocation

class CountrySettings: ObservableObject {
    @Published var selectedCountry = "vn"

    var styleURL: URL {
        let styleUrl = MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
        return URL(string: styleUrl)!
    }

    var location: CLLocationCoordinate2D {
        let location = MapUtils.getLatlng(idCountry: selectedCountry)
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    var zoomLevel: Double {
        return MapUtils.zoom(idCountry: selectedCountry)
    }
}
