//
//  MarkerManager.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 27/12/2023.
//

import TrackAsia

class MarkerManager: ObservableObject {
    @Published var mapView: MLNMapView? 
    @Published var polyline: MLNPolyline?
    @Published var polygon: MLNPolygon?
    @Published var markers: [MLNPointAnnotation] = []

    func addMarker(at coordinate: CLLocationCoordinate2D, title: String?, zoomlevel: Double? = 5) {
        if let mapView = mapView {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            markers.append(annotation)
            mapView.addAnnotation(annotation)
            mapView.setCenter(coordinate, zoomLevel: zoomlevel ?? 5, animated: true)
        }
    }

    func clearMarkers() {
        mapView?.removeAnnotations(markers)
        markers.removeAll()
    }
    
    func addPolyline(at coordinate: CLLocationCoordinate2D) {
        if let mapView = mapView {
            guard markers.count >= 1 else { return }
            
            var coordinates: [CLLocationCoordinate2D] = []
            for marker in markers {
                coordinates.append(marker.coordinate)
            }
            polyline = MLNPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
            mapView.add(polyline!)
        }
    }
    
    func addPolygon(at coordinate: CLLocationCoordinate2D) {
           guard markers.count >= 1 else { return }

           var coordinates: [CLLocationCoordinate2D] = []
           for marker in markers {
               coordinates.append(marker.coordinate)
           }

           polygon = MLNPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
        mapView?.add(polygon!)
       }
}
