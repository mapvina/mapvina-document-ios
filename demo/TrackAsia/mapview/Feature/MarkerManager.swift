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
    
    func addPolyline(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty, coordinates.count >= 2 else {
            print("Cần ít nhất 2 tọa độ để tạo polyline")
            return
        }
        
        // Tạo polyline MLN từ danh sách tọa độ
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        polyline.title = "Feature polyline"
        
        // Định nghĩa thuộc tính hiển thị
        if let mapView = mapView {
            mapView.add(polyline)
            
            // Zoom đến mức vừa đủ để hiển thị polyline
            let bounds = getCoordinateBounds(for: coordinates)
            let insets = UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80)
            mapView.setVisibleCoordinateBounds(bounds, edgePadding: insets, animated: true)
        }
    }
    
    // Thêm phương thức xử lý polygon với danh sách tọa độ
    func addPolygon(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty, coordinates.count >= 3 else {
            print("Cần ít nhất 3 tọa độ để tạo polygon")
            return
        }
        
        // Tạo polygon MLN từ danh sách tọa độ
        let polygon = MLNPolygon(coordinates: coordinates, count: UInt(coordinates.count))
        polygon.title = "Feature polygon"
        
        // Định nghĩa thuộc tính hiển thị
        if let mapView = mapView {
            mapView.add(polygon)
            
            // Zoom đến mức vừa đủ để hiển thị polygon
            let bounds = getCoordinateBounds(for: coordinates)
            let insets = UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80)
            mapView.setVisibleCoordinateBounds(bounds, edgePadding: insets, animated: true)
        }
    }
    
    // Helper để tính toán bounds từ danh sách tọa độ
    private func getCoordinateBounds(for coordinates: [CLLocationCoordinate2D]) -> MLNCoordinateBounds {
        // Tìm tọa độ nhỏ nhất và lớn nhất
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        // Tạo northeast và southwest
        let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng)
        let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLng)
        
        return MLNCoordinateBounds(sw: southwest, ne: northeast)
    }
}
