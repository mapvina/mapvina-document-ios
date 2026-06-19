//
//  MapViewManager.swift
//  MapVina
//
//  Created by SangNguyen on 19/02/2024.
//

import Foundation
import MapVina
import MapboxNavigation
import CoreLocation

class MapViewManager: ObservableObject {
    @Published var zoomLevelCurrent = 10.0
    @Published var locationDefault = CLLocationCoordinate2D(latitude: 16.455783, longitude: 106.709200)
    @Published var mapView: MLNMapView
    @Published var selectedLocation: (CLLocationCoordinate2D, String?)?
    var onLocationSelectedCallback: ((CLLocationCoordinate2D, String?) -> Void)?
    @Published var is3D = false
    private var animationPolylineView: PolylineView?
    private var polylines: [MLNPolyline] = []
    private var polygons: [MLNPolygon] = []

    func invokeOnLocationSelected(coordinate: CLLocationCoordinate2D, name: String?) {
        onLocationSelectedCallback?(coordinate, name)
    }

    init() {
        // Tạo MapView với style mặc định
        let styleURL = URL(string: "https://maps.map-vina.com/styles/v1/streets.json?key=public_key")!
        mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Thiết lập các thuộc tính khác cho map view
        mapView.logoView.isHidden = false
        mapView.compassView.isHidden = false
        mapView.showsUserLocation = true
        mapView.showsUserHeadingIndicator = true
        
        setupMapView()
    }

    private func setupMapView() {
        // Cài đặt các thuộc tính ban đầu
        mapView.minimumZoomLevel = 3
        mapView.maximumZoomLevel = 20
    }

    func addMarker(at coordinate: CLLocationCoordinate2D, title: String?) {
        print("🏁 MapViewManager - Adding marker at: \(coordinate.latitude), \(coordinate.longitude)")
        
        // KHÔNG xóa những annotation khác nữa, chỉ thêm mới
        // Chỉ xóa các annotation có cùng tọa độ nếu cần
        if let existingAnnotations = mapView.annotations {
            let annotationsToRemove = existingAnnotations.compactMap { annotation -> MLNAnnotation? in
                if let pointAnnotation = annotation as? MLNPointAnnotation,
                   abs(pointAnnotation.coordinate.latitude - coordinate.latitude) < 0.0001 &&
                   abs(pointAnnotation.coordinate.longitude - coordinate.longitude) < 0.0001 {
                    return annotation
                }
                return nil
            }
            
            if !annotationsToRemove.isEmpty {
                print("🗑️ Removing \(annotationsToRemove.count) existing annotations at same location")
                mapView.removeAnnotations(annotationsToRemove)
            }
        }
        
        print("📍 Creating new annotation at \(coordinate.latitude), \(coordinate.longitude)")
        
        // Create and add the new annotation
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title ?? "Vị trí đã chọn"
        
        // Debug current style state
        if mapView.style == nil {
            print("⚠️ Map style is nil - this could prevent markers from appearing")
        }
        
        // Đảm bảo đẩy việc thêm annotation vào main thread
        DispatchQueue.main.async {
            // Thêm annotation vào map
            self.mapView.addAnnotation(annotation)
            
            // Kiểm tra nếu annotation đã được thêm thành công
            if let annotations = self.mapView.annotations {
                let added = annotations.contains { item in
                    if let point = item as? MLNPointAnnotation,
                       abs(point.coordinate.latitude - coordinate.latitude) < 0.0001 &&
                       abs(point.coordinate.longitude - coordinate.longitude) < 0.0001 {
                        return true
                    }
                    return false
                }
                
                if added {
                    print("✅ Marker added successfully with title: \(title ?? "No Title")")
                } else {
                    print("❌ Failed to find marker in map's annotations after adding")
                }
                
                print("📊 Total annotations on map: \(annotations.count)")
            }
            
            // Center the map on the new marker
            self.mapView.setCenter(coordinate, zoomLevel: 14, animated: true)
        }
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

    func addPolyline(coordinates: [CLLocationCoordinate2D]) {
        // Tạo polyline
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        // Thiết lập polyline style
        if let style = mapView.style {
            let source = MLNShapeSource(identifier: "polyline-source-\(UUID().uuidString)", shape: polyline, options: nil)
            style.addSource(source)
            
            let layer = MLNLineStyleLayer(identifier: "polyline-layer-\(UUID().uuidString)", source: source)
            layer.lineColor = NSExpression(forConstantValue: UIColor.blue)
            layer.lineWidth = NSExpression(forConstantValue: 3.0)
            layer.lineOpacity = NSExpression(forConstantValue: 0.8)
            
            style.addLayer(layer)
            
            // Lưu lại polyline để có thể xóa sau này
            polylines.append(polyline)
        }
    }
    
    // Overload với tham số color và lineWidth
    func addPolyline(coordinates: [CLLocationCoordinate2D], color: UIColor, lineWidth: CGFloat) {
        print("🖌️ Adding polyline with \(coordinates.count) points, color: \(color), width: \(lineWidth)")
        
        // Tạo polyline
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        // Thiết lập polyline style
        if let style = mapView.style {
            let source = MLNShapeSource(identifier: "polyline-source-\(UUID().uuidString)", shape: polyline, options: nil)
            style.addSource(source)
            
            let layer = MLNLineStyleLayer(identifier: "polyline-layer-\(UUID().uuidString)", source: source)
            layer.lineColor = NSExpression(forConstantValue: color)
            layer.lineWidth = NSExpression(forConstantValue: lineWidth)
            layer.lineOpacity = NSExpression(forConstantValue: 0.8)
            
            style.addLayer(layer)
            
            // Lưu lại polyline để có thể xóa sau này
            polylines.append(polyline)
            
            print("✅ Polyline added successfully")
        } else {
            print("⚠️ Cannot add polyline: map style is nil")
        }
    }
    
    // Thêm phương thức fitBounds để điều chỉnh góc nhìn bản đồ
    func fitBounds(southwest: CLLocationCoordinate2D, northeast: CLLocationCoordinate2D, padding: CGFloat) {
        print("🔍 Fitting map to bounds: SW(\(southwest.latitude), \(southwest.longitude)) - NE(\(northeast.latitude), \(northeast.longitude)) with padding \(padding)")
        
        // Tính toán center point
        let centerLat = (southwest.latitude + northeast.latitude) / 2
        let centerLng = (southwest.longitude + northeast.longitude) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        // Tính toán zoom level dựa trên khoảng cách
        let latDelta = abs(northeast.latitude - southwest.latitude)
        let lngDelta = abs(northeast.longitude - southwest.longitude)
        
        // Tính toán zoom level dựa trên khoảng cách
        // Giả sử tỉ lệ ban đầu
        var zoomLevel = 16.0
        
        // Điều chỉnh zoom theo độ lớn của bounds
        let maxDelta = max(latDelta, lngDelta)
        if maxDelta > 0 {
            // Logarithm-based zoom adjustment
            // 0.0005 is approximately city block level (zoom ~16)
            // 10 degrees is country level (zoom ~4)
            if maxDelta > 10 {
                zoomLevel = 2 // Continental view
            } else if maxDelta > 5 {
                zoomLevel = 3 // Large country
            } else if maxDelta > 1 {
                zoomLevel = 5 // Small country
            } else if maxDelta > 0.5 {
                zoomLevel = 7 // Region
            } else if maxDelta > 0.1 {
                zoomLevel = 9 // City
            } else if maxDelta > 0.05 {
                zoomLevel = 11 // District
            } else if maxDelta > 0.01 {
                zoomLevel = 13 // Neighborhood
            } else if maxDelta > 0.005 {
                zoomLevel = 14 // Streets
            } else if maxDelta > 0.001 {
                zoomLevel = 15 // Buildings
            } else {
                zoomLevel = 16 // Detail view
            }
        }
        
        // Điều chỉnh zoom để tính đến padding
        if padding > 0 {
            // Giảm zoom khi padding lớn
            zoomLevel = max(2, zoomLevel - log10(padding / 50.0))
        }
        
        print("🔍 Calculated zoom level: \(zoomLevel)")
        
        // Di chuyển camera
        mapView.setCenter(centerCoordinate, zoomLevel: zoomLevel, animated: true)
    }
    
    func addPolygon(coordinates: [CLLocationCoordinate2D]) {
        // Tạo polygon
        let polygon = MLNPolygon(coordinates: coordinates, count: UInt(coordinates.count))
        
        // Thiết lập polygon style
        if let style = mapView.style {
            let source = MLNShapeSource(identifier: "polygon-source-\(UUID().uuidString)", shape: polygon, options: nil)
            style.addSource(source)
            
            // Tạo fill layer
            let fillLayer = MLNFillStyleLayer(identifier: "polygon-fill-layer-\(UUID().uuidString)", source: source)
            fillLayer.fillColor = NSExpression(forConstantValue: UIColor.blue.withAlphaComponent(0.4))
            fillLayer.fillOutlineColor = NSExpression(forConstantValue: UIColor.blue)
            fillLayer.fillOpacity = NSExpression(forConstantValue: 0.6)
            
            style.addLayer(fillLayer)
            
            // Tạo outline layer
            let outlineLayer = MLNLineStyleLayer(identifier: "polygon-outline-layer-\(UUID().uuidString)", source: source)
            outlineLayer.lineColor = NSExpression(forConstantValue: UIColor.blue)
            outlineLayer.lineWidth = NSExpression(forConstantValue: 2.0)
            
            style.addLayer(outlineLayer)
            
            // Lưu lại polygon để có thể xóa sau này
            polygons.append(polygon)
        }
    }
    
    func addAnimationPolyline(coordinates: [CLLocationCoordinate2D]) {
        // Xóa animation polyline cũ nếu có
        if let oldPolylineView = animationPolylineView {
            oldPolylineView.stopAnimation()
        }
        
        // Tạo animation polyline mới
        animationPolylineView = PolylineView(coordinates: coordinates)
        
        // Thêm vào map nếu style đã sẵn sàng
        if let style = mapView.style {
            animationPolylineView?.addPolyline(to: style, mapview: mapView)
        }
    }
    
    func startAnimatingPolyline() {
        animationPolylineView?.animatePolyline()
    }
    
    func stopAnimatingPolyline() {
        animationPolylineView?.stopAnimation()
    }
    
    func removeAllPolylines() {
        // Xóa tất cả polyline khỏi bản đồ
        guard let style = mapView.style else { return }
        
        for polyline in polylines {
            // Tìm và xóa các source và layer liên quan đến polyline
            let sources: Set<MLNSource>? = style.sources
            guard let styleSourcesSet = sources else { continue }
            
            for source in styleSourcesSet {
                guard let shapeSource = source as? MLNShapeSource,
                      let shape = shapeSource.shape as? MLNPolyline,
                      shape === polyline else { continue }
                
                // Lưu ID của source
                let sourceID = source.identifier
                
                // Tìm và xóa các layer sử dụng source này
                let styleLayers: [MLNStyleLayer]? = style.layers
                if let layersArray = styleLayers {
                    for layer in layersArray {
                        // Kiểm tra xem layer có liên kết với source không
                        if let lineLayer = layer as? MLNLineStyleLayer,
                           lineLayer.description.contains(sourceID) {
                            style.removeLayer(layer)
                        }
                        
                        if let fillLayer = layer as? MLNFillStyleLayer,
                           fillLayer.description.contains(sourceID) {
                            style.removeLayer(layer)
                        }
                    }
                }
                
                // Xóa source
                style.removeSource(source)
            }
        }
        
        // Xóa danh sách
        polylines.removeAll()
    }
    
    func removeAllPolygons() {
        // Xóa tất cả polygon khỏi bản đồ
        guard let style = mapView.style else { return }
        
        for polygon in polygons {
            // Tìm và xóa các source và layer liên quan đến polygon
            let sources: Set<MLNSource>? = style.sources
            guard let styleSourcesSet = sources else { continue }
            
            for source in styleSourcesSet {
                guard let shapeSource = source as? MLNShapeSource,
                      let shape = shapeSource.shape as? MLNPolygon,
                      shape === polygon else { continue }
                
                // Lưu ID của source
                let sourceID = source.identifier
                
                // Tìm và xóa các layer sử dụng source này
                let styleLayers: [MLNStyleLayer]? = style.layers
                if let layersArray = styleLayers {
                    for layer in layersArray {
                        // Kiểm tra xem layer có liên kết với source không
                        if let lineLayer = layer as? MLNLineStyleLayer,
                           lineLayer.description.contains(sourceID) {
                            style.removeLayer(layer)
                        }
                        
                        if let fillLayer = layer as? MLNFillStyleLayer,
                           fillLayer.description.contains(sourceID) {
                            style.removeLayer(layer)
                        }
                    }
                }
                
                // Xóa source
                style.removeSource(source)
            }
        }
        
        // Xóa danh sách
        polygons.removeAll()
    }
    
    func removeAllShapes() {
        // Xóa tất cả polyline và polygon
        removeAllPolylines()
        removeAllPolygons()
        
        // Xóa animation polyline
        if let polylineView = animationPolylineView {
            polylineView.stopAnimation()
            animationPolylineView = nil
        }
    }
}
