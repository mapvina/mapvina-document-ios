//
//  MapUtils.swift
//  MapVina
//
//  Created by SangNguyen on 10/01/2024.
//

import Foundation
import SwiftUI
import MapVina
import CoreLocation

public struct LatLng {
    public var latitude: Double
    public var longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Thêm phương thức chuyển đổi sang CLLocationCoordinate2D
    public func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// Thêm extension để mở rộng CLLocationCoordinate2D
public extension CLLocationCoordinate2D {
    // Chuyển đổi từ CLLocationCoordinate2D sang LatLng
    func toLatLng() -> LatLng {
        return LatLng(latitude: latitude, longitude: longitude)
    }
}

class MapUtils {
    static func urlStyle(idCountry: String?, is3D: Bool? = false) -> String {
        guard let idCountry = idCountry else {
            return Constants.urlStyleVN
        }
        
        switch idCountry {
        case "vn":
            return is3D == false ? Constants.urlStyleVN : Constants.urlStyle3DVN
        case "sg":
            return is3D == false ? Constants.urlStyleSG : Constants.urlStyle3DSG
        case "th":
            return is3D == false ? Constants.urlStyleTH : Constants.urlStyle3DTH
        default:
            return is3D == false ? Constants.urlStyleVN : Constants.urlStyle3DVN
        }
    }
    
    static func urlDomain(idCountry: String) -> String {
        print("🌐 urlDomain called with idCountry: \(idCountry)")
        switch idCountry.lowercased() {
        case "vn":
            return "https://maps.mapvina.com"
        case "sg": 
            return "https://sg-maps.mapvina.com"
        case "th": 
            return "https://th-maps.mapvina.com"
        case "vietnam":
            print("✅ Using Vietnam API")
            return "https://maps.mapvina.com"
        default:
            return "https://maps.mapvina.com"
        }
    }
    
    static func zoom(idCountry: String?) -> Double {
        switch idCountry {
            case "vn":
                return 6.0
            case "sg":
                return 10.0
            case "th":
                return 10.0
            default:
                return 10.0
        }
    }
    
    static func getNameContry(idCountry: String) -> String {
        switch idCountry {
        case "vn": return "Việt Nam"
        case "sg": return "Singapore"
        case "th": return "Thailand"
        default: return "Việt Nam"
        }
    }
    
    static func getCoordinate(idCountry: String) -> CLLocationCoordinate2D {        
        switch idCountry {
        case "vn":
            return CLLocationCoordinate2D(latitude: 10.728073, longitude: 106.624054)
        case "sg":
            return CLLocationCoordinate2D(latitude: 1.3302, longitude: 103.8104)
        case "th":
            return CLLocationCoordinate2D(latitude: 13.27, longitude: 101.96)
        default:
            return CLLocationCoordinate2D(latitude: 10.728073, longitude: 106.624054)
        }
    }
    
    static func getLatlng(idCountry: String?) -> LatLng {
        guard let idCountry = idCountry else {
            return LatLng(latitude: 10.728073, longitude: 106.624054)
        }
        
        switch idCountry {
        case "vn":
            return LatLng(latitude: 10.728073, longitude: 106.624054)
        case "sg":
            return LatLng(latitude: 1.3302, longitude: 103.8104)
        case "th":
            return LatLng(latitude: 13.27, longitude: 101.96)
        default:
            return LatLng(latitude: 10.728073, longitude: 106.624054)
        }
    }
}
