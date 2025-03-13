//
//  MapUtils.swift
//  TrackAsia
//
//  Created by SangNguyen on 10/01/2024.
//

import Foundation
import SwiftUI
import TrackAsia

struct LatLng {
    var latitude: Double
    var longitude: Double
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
        case "tw":
            return is3D == false ? Constants.urlStyleTW : Constants.urlStyle3DTW
        case "my":
            return is3D == false ? Constants.urlStyleMI : Constants.urlStyle3DMI
        default:
            return is3D == false ? Constants.urlStyleVN : Constants.urlStyle3DVN
        }
    }
    
    static func urlDomain(idCountry: String?) -> String {
        guard let idCountry = idCountry else {
            return Constants.baseurl
        }
        
        switch idCountry {
        case "vn": return Constants.baseurl
        case "sg": return Constants.baseurlSG
        case "th": return Constants.baseurlTH
        case "tw": return Constants.baseurlTW
        case "my": return Constants.baseurlMI
        default: return Constants.baseurl
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
            case  "my":
                return 8.0
            case "tw" :
                return 8.0
            default:
                return 10.0
        }
    }
    
    static func getNameContry(idCountry: String) -> String {
        switch idCountry {
        case "vn": return "Việt Nam"
        case "sg": return "Singapore"
        case "th": return "Thailand"
        case "tw": return "Taiwan"
        case "my": return "Malaysia"
        default: return "Việt Nam"
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
        case "tw":
            return LatLng(latitude: 23.670467, longitude: 120.960998)
        case "my":
            return LatLng(latitude: 3.5799465, longitude: 102.2791128)
        default:
            return LatLng(latitude: 10.728073, longitude: 106.624054)
        }
    }
}
