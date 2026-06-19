//
//  MapViewController.swift
//  MapVinaDemo
//
//  Created by SangNguyen on 13/12/2023.
//  Updated with combined utils functionality
//

import Foundation
import SwiftUI
import MapVina
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapKit
import Alamofire
import Combine


// MARK: - MapViewMode
enum MapMode {
    case singlePoint
    case wayPoint
    case cluster
    case animation
    case feature
    case compare
}

// MARK: - MapViewModel
class MapViewModel: ObservableObject {
    @Published var mapViewManager = MapViewManager()
    @Published var mode: MapMode = .singlePoint
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var currentRoute: Route?
    @Published var isAnimating: Bool = false
    @Published var addresses: [AddressModel] = []
    @Published var isStyleLoaded: Bool = false
    @Published var isMapReady: Bool = false
    @Published var showTapSheet: Bool = false
    @Published var featureOptions: [String: Bool] = [
        "showMarkers": false,
        "showPolyline": false,
        "showPolygon": false,
        "showHeatmap": false,
        "showBuildings3D": false
    ]
    @Published var searchText: String
    var tappedCoordinate: CLLocationCoordinate2D?
    var mapViewInstance: MLNMapView? { return mapViewManager.mapView }
    
    // Private properties to prevent publishing updates during view refresh
    private var geocodingRepository = GeocodingRepository()
    private var addressRepository = AddressRepository()
    private var styleLoadingTask: DispatchWorkItem?
    private var lastMapUpdate: Date = Date()
    private let updateCooldown: TimeInterval = 0.3 // Prevent rapid updates
    
    // Callback for map tap events
    var onMapTapped: ((CLLocationCoordinate2D) -> Void)?
    
    // Marker management
    private var queuedMarkers = [String: (coordinate: CLLocationCoordinate2D, title: String?, retryCount: Int)]()
    private var isProcessingQueue = false
    private let maxRetryCount = 5
    
    init() {
        // Initialize searchText before calling setupMapObservers
        searchText = ""
        // Set isMapReady before calling any methods
        self.isMapReady = true
        // Now call setupMapObservers after all properties are initialized
        self.setupMapObservers()
    }
    
    // MARK: - Feature Methods
    
    func toggleFeatureOption(_ option: String) {
        if let currentValue = featureOptions[option] {
            featureOptions[option] = !currentValue
            print("🔄 Toggled feature option \(option) to \(!currentValue)")
            
            // Áp dụng thay đổi lên bản đồ
            applyFeatureOptionChange(option: option, isEnabled: !currentValue)
        } else {
            print("⚠️ Unknown feature option: \(option)")
        }
    }
    
    private func applyFeatureOptionChange(option: String, isEnabled: Bool) {
        DispatchQueue.main.async {
            switch option {
            case "showMarkers":
                self.toggleMarkers(isEnabled: isEnabled)
            case "showPolyline":
                self.togglePolyline(isEnabled: isEnabled)
            case "showPolygon":
                self.togglePolygon(isEnabled: isEnabled)
            case "showHeatmap":
                self.toggleHeatmap(isEnabled: isEnabled)
            case "showBuildings3D":
                self.toggle3DBuildings(isEnabled: isEnabled)
            default:
                break
            }
        }
    }
    
    private func toggleMarkers(isEnabled: Bool) {
        if isEnabled {
            // Thêm các marker mẫu quanh vị trí trung tâm
            let centerCoordinate = mapViewManager.mapView.centerCoordinate
            let points = generateRandomPoints(around: centerCoordinate, count: 5, radiusInKm: 2)
            
            for (index, point) in points.enumerated() {
                addMarker(at: point, title: "Feature Marker \(index + 1)")
            }
        } else {
            // Xóa các marker có title bắt đầu bằng "Feature Marker"
            if let annotations = mapViewManager.mapView.annotations?.filter({ 
                $0.title?!.hasPrefix("Feature Marker") ?? false 
            }) {
                mapViewManager.mapView.removeAnnotations(annotations)
            }
        }
    }
    
    private func togglePolyline(isEnabled: Bool) {
        if isEnabled {
            // Tạo polyline mẫu
            let centerCoordinate = mapViewManager.mapView.centerCoordinate
            let offset = 0.01
            let coordinates = [
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude - offset, longitude: centerCoordinate.longitude - offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude + offset, longitude: centerCoordinate.longitude - offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude + offset, longitude: centerCoordinate.longitude + offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude - offset, longitude: centerCoordinate.longitude + offset)
            ]
            
            // Tạo polyline với coordinates
            if let style = mapViewManager.mapView.style {
                let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
                polyline.title = "Feature Polyline"
                
                let source = MLNShapeSource(identifier: "feature-polyline-source", shape: polyline, options: nil)
                style.addSource(source)
                
                let layer = MLNLineStyleLayer(identifier: "feature-polyline-layer", source: source)
                layer.lineColor = NSExpression(forConstantValue: UIColor.red)
                layer.lineWidth = NSExpression(forConstantValue: 3)
                style.addLayer(layer)
            }
        } else {
            // Xóa polyline
            if let style = mapViewManager.mapView.style {
                if let layer = style.layer(withIdentifier: "feature-polyline-layer") {
                    style.removeLayer(layer)
                }
                if let source = style.source(withIdentifier: "feature-polyline-source") {
                    style.removeSource(source)
                }
            }
        }
    }
    
    private func togglePolygon(isEnabled: Bool) {
        if isEnabled {
            // Tạo polygon mẫu
            let centerCoordinate = mapViewManager.mapView.centerCoordinate
            let offset = 0.02
            var coordinates = [
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude - offset, longitude: centerCoordinate.longitude - offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude + offset, longitude: centerCoordinate.longitude - offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude + offset, longitude: centerCoordinate.longitude + offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude - offset, longitude: centerCoordinate.longitude + offset),
                CLLocationCoordinate2D(latitude: centerCoordinate.latitude - offset, longitude: centerCoordinate.longitude - offset) // Đóng polygon
            ]
            
            // Tạo polygon với coordinates
            if let style = mapViewManager.mapView.style {
                let polygon = MLNPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
                polygon.title = "Feature Polygon"
                
                let source = MLNShapeSource(identifier: "feature-polygon-source", shape: polygon, options: nil)
                style.addSource(source)
                
                let layer = MLNFillStyleLayer(identifier: "feature-polygon-layer", source: source)
                layer.fillColor = NSExpression(forConstantValue: UIColor.blue.withAlphaComponent(0.5))
                layer.fillOutlineColor = NSExpression(forConstantValue: UIColor.blue)
                style.addLayer(layer)
            }
        } else {
            // Xóa polygon
            if let style = mapViewManager.mapView.style {
                if let layer = style.layer(withIdentifier: "feature-polygon-layer") {
                    style.removeLayer(layer)
                }
                if let source = style.source(withIdentifier: "feature-polygon-source") {
                    style.removeSource(source)
                }
            }
        }
    }
    
    private func toggleHeatmap(isEnabled: Bool) {
        if isEnabled {
            // Tạo heatmap mẫu
            let centerCoordinate = mapViewManager.mapView.centerCoordinate
            let points = generateRandomPoints(around: centerCoordinate, count: 100, radiusInKm: 5)
            
            if let style = mapViewManager.mapView.style {
                // Tạo feature collection
                var features: [MLNPointFeature] = []
                for point in points {
                    let feature = MLNPointFeature()
                    feature.coordinate = point
                    feature.attributes = ["magnitude": Int.random(in: 1...10)]
                    features.append(feature)
                }
                
                let featureCollection = MLNShapeCollectionFeature(shapes: features)
                let source = MLNShapeSource(identifier: "feature-heatmap-source", shape: featureCollection, options: nil)
                style.addSource(source)
                
                // Tạo heatmap layer
                let heatmapLayer = MLNHeatmapStyleLayer(identifier: "feature-heatmap-layer", source: source)
                heatmapLayer.heatmapWeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:(magnitude, 'linear', nil, %@)",
                                                         [0: 0, 10: 1])
                heatmapLayer.heatmapIntensity = NSExpression(forConstantValue: 1)
                heatmapLayer.heatmapRadius = NSExpression(forConstantValue: 20)
                heatmapLayer.heatmapColor = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:(heatmapDensity, 'linear', nil, %@)",
                                                        [0.1: UIColor.blue, 0.3: UIColor.green, 0.5: UIColor.yellow, 0.7: UIColor.orange, 1.0: UIColor.red])
                style.addLayer(heatmapLayer)
            }
        } else {
            // Xóa heatmap
            if let style = mapViewManager.mapView.style {
                if let layer = style.layer(withIdentifier: "feature-heatmap-layer") {
                    style.removeLayer(layer)
                }
                if let source = style.source(withIdentifier: "feature-heatmap-source") {
                    style.removeSource(source)
                }
            }
        }
    }
    
    private func toggle3DBuildings(isEnabled: Bool) {
        if isEnabled {
            // Hiển thị 3D buildings
            if let style = mapViewManager.mapView.style {
                // Kiểm tra xem layer building đã tồn tại chưa
                if let _ = style.layer(withIdentifier: "3d-buildings") {
                    return
                }
                
                // Tạo layer 3D buildings
                let fillExtrusionLayer = MLNFillExtrusionStyleLayer(identifier: "3d-buildings", source: style.source(withIdentifier: "composite")!)
                fillExtrusionLayer.sourceLayerIdentifier = "building"
                let predicate = NSPredicate(format: "extrude == 'true'")
                fillExtrusionLayer.predicate = predicate
                fillExtrusionLayer.fillExtrusionHeight = NSExpression(format: "height")
                fillExtrusionLayer.fillExtrusionBase = NSExpression(format: "min_height")
                fillExtrusionLayer.fillExtrusionColor = NSExpression(forConstantValue: UIColor(red: 0.59, green: 0.65, blue: 0.66, alpha: 1.0))
                fillExtrusionLayer.fillExtrusionOpacity = NSExpression(forConstantValue: 0.9)
                
                style.addLayer(fillExtrusionLayer)
            }
        } else {
            // Xóa 3D buildings
            if let style = mapViewManager.mapView.style {
                if let layer = style.layer(withIdentifier: "3d-buildings") {
                    style.removeLayer(layer)
                }
                
                // Reset the pitch to flat view (0 degrees)
                mapViewManager.mapView.setCamera(MLNMapCamera(
                    lookingAtCenter: mapViewManager.mapView.centerCoordinate,
                    fromDistance: 1000,
                    pitch: 0,
                    heading: 0), animated: true)
            }
        }
    }
    
    // MARK: - Animation Methods
    
    func startAnimatingPolyline() {
        if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
            if let animationLine = coordinator.animationLineView {
                animationLine.startAnimation()
                isAnimating = true
                print("👉 Started polyline animation")
            } else {
                print("⚠️ No animation line available to start")
                coordinator.setupAnimationMode()
                
                // Retry after setup
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let animationLine = coordinator.animationLineView {
                        animationLine.startAnimation()
                        self.isAnimating = true
                        print("👉 Started polyline animation after setup")
                    }
                }
            }
        }
    }
    
    func stopAnimatingPolyline() {
        if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
            if let animationLine = coordinator.animationLineView {
                animationLine.stopAnimation()
                isAnimating = false
                print("🛑 Stopped polyline animation")
            }
        }
    }
    
    func setupMapObservers() {
        // Add observers for map state changes if needed
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            self?.handleAppForeground()
        }
        
        // Add observer to know when map style is loaded
        NotificationCenter.default.addObserver(forName: NSNotification.Name("StyleLoadedNotification"), 
                                              object: nil, 
                                              queue: .main) { [weak self] _ in
            print("✅ Style loaded notification received")
            self?.isStyleLoaded = true
            // Thiết lập isMapReady = true sau khi style được tải
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.isMapReady = true
                print("✅ Map is now ready for adding markers")
            }
        }
    }
    
    private func handleAppForeground() {
        // Refresh map when app comes to foreground
        if let country = UserDefaults.standard.string(forKey: "selectedCountry") {
            updateMap(selectedCountry: country)
        }
    }
    
    func prepareForModeChange() {
        // Only clean up what's necessary for the current mode
        // Don't do heavy operations here as it might cause lag
        print("Preparing for mode change from \(mode)")
        
        // Stop animations if running
        if isAnimating {
            isAnimating = false
            
            if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                if coordinator.animationLineView?.isAnimating == true {
                    coordinator.animationLineView?.stopAnimation()
                }
            }
        }
        
        // Remember we'll do the selective cleaning later
        // This is just to prepare the state change
    }
    
    // Update map with selected country
    func updateMap(selectedCountry: String) {
        // Add update cooldown to prevent rapid consecutive updates
        let now = Date()
        guard now.timeIntervalSince(lastMapUpdate) > updateCooldown else {
            print("⚠️ Map update skipped - cooldown period active")
            return
        }
        lastMapUpdate = now
        
        // Kiểm tra xem style URL đã thay đổi chưa
        let newStyleUrl = MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
        let currentStyleUrlString = mapViewManager.mapView.styleURL?.absoluteString ?? ""
        
        // Nếu style không thay đổi, chỉ cập nhật center và zoom
        if currentStyleUrlString == newStyleUrl {
            print("Style URL unchanged, updating only map center and zoom")
            updateMapCenterAndZoom(for: selectedCountry)
            return
        }
        
        // Cancel any pending style loading task
        styleLoadingTask?.cancel()
        
        let newTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Reset states
            self.isStyleLoaded = false
            self.isMapReady = false
            
            // Chuẩn bị dữ liệu cũ trước khi làm mới style
            self.prepareStateForStyleChange()
            
            // Update the map style and center
            self.updateMapStyle(to: newStyleUrl)
            self.updateMapCenterAndZoom(for: selectedCountry)
        }
        
        styleLoadingTask = newTask
        DispatchQueue.main.async(execute: newTask)
    }
    
    // Prepares state before style change to maintain continuity
    private func prepareStateForStyleChange() {
        // Save current camera position
        let currentCenter = mapViewManager.mapView.centerCoordinate
        let currentZoom = mapViewManager.mapView.zoomLevel
        
        // Store waypoints and other important states if needed
        // This will help restore state after style change
        if mode == .wayPoint {
            // Waypoints are already stored in the waypoints array
            // No need to extract them again from the map
        } else if mode == .singlePoint {
            // Selected location is already stored
        }
    }
    
    // Updates map style with animation
    private func updateMapStyle(to styleUrlString: String) {
        DispatchQueue.main.async {
            print("Updating map style to: \(styleUrlString)")
            UIView.transition(with: self.mapViewManager.mapView, 
                             duration: 0.3, 
                             options: .transitionCrossDissolve, 
                             animations: {
                self.mapViewManager.mapView.styleURL = URL(string: styleUrlString)
            }, completion: nil)
        }
    }
    
    // Updates map center and zoom level
    private func updateMapCenterAndZoom(for selectedCountry: String) {
        let latLng = MapUtils.getLatlng(idCountry: selectedCountry)
        let zoom = MapUtils.zoom(idCountry: selectedCountry)
        
        // Create new camera position
        let newCenter = latLng.toCLLocationCoordinate2D()
        
        // Update map properties
        DispatchQueue.main.async {
            // Update camera with animation
            self.mapViewManager.mapView.setCenter(newCenter, zoomLevel: zoom, animated: true)
            
            // Set map as ready after camera update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isMapReady = true
                
                // Restore state based on mode
                self.restoreMapState()
            }
        }
    }
    
    // Only clear elements relevant to the current mode
    func selectivelyUpdateMapForMode() {
        let mapView = mapViewManager.mapView
        
        switch mode {
        case .singlePoint:
            // For single point mode, only remove selected location marker
            if let annotations = mapView.annotations {
                let singlePointAnnotations = annotations.filter { annotation in
                    if let title = annotation.title, title!.contains("Selected") || title!.contains("Vị trí đã chọn") {
                        return true
                    }
                    return false
                }
                if !singlePointAnnotations.isEmpty {
                    mapView.removeAnnotations(singlePointAnnotations)
                }
            }
            
        case .wayPoint:
            // For waypoint mode, only remove waypoint annotations and route
            if let annotations = mapView.annotations {
                let waypointAnnotations = annotations.filter { annotation in
                    if let title = annotation.title, title!.contains("Waypoint") || title!.contains("Điểm") {
                        return true
                    }
                    return false
                }
                if !waypointAnnotations.isEmpty {
                    mapView.removeAnnotations(waypointAnnotations)
                }
            }
            
            // Clear route overlays
            let routeOverlays = mapView.overlays.filter { overlay in
                if let title = overlay.title, title!.contains("Route") {
                    return true
                }
                return false
            }
            if !routeOverlays.isEmpty {
                mapView.removeOverlays(routeOverlays)
            }
            
        case .cluster:
            // For cluster mode, only remove cluster annotations
            if let annotations = mapView.annotations {
                let clusterAnnotations = annotations.filter { annotation in
                    if let title = annotation.title, title!.contains("Cluster") {
                        return true
                    }
                    return false
                }
                if !clusterAnnotations.isEmpty {
                    mapView.removeAnnotations(clusterAnnotations)
                }
            }
            
        case .animation:
            // For animation mode, stop animation and clear animation overlays
            isAnimating = false
            
            // Remove animation polylines
            let animationOverlays = mapView.overlays.filter { overlay in
                if let title = overlay.title, title!.contains("Animation") {
                    return true
                }
                return false
            }
            if !animationOverlays.isEmpty {
                mapView.removeOverlays(animationOverlays)
            }
            
        case .feature, .compare:
            // For feature mode, remove feature-specific elements
            if let annotations = mapView.annotations {
                let featureAnnotations = annotations.filter { annotation in
                    if let title = annotation.title, title!.contains("Feature") {
                        return true
                    }
                    return false
                }
                if !featureAnnotations.isEmpty {
                    mapView.removeAnnotations(featureAnnotations)
                }
            }
            
            // Remove feature overlays
            let featureOverlays = mapView.overlays.filter { overlay in
                if let title = overlay.title, title!.contains("Feature") {
                    return true
                }
                return false
            }
            if !featureOverlays.isEmpty {
                mapView.removeOverlays(featureOverlays)
            }
        }
    }
    
    // New method to update mode without clearing map
    func updateMode(_ newMode: MapMode) {
        // Không làm gì nếu mode không thay đổi
        if mode == newMode {
            return
        }
        
        print("Map mode changing from \(mode) to \(newMode)")
        
        // Xử lý dọn dẹp cho mode cũ trước khi chuyển sang mode mới
        switch mode {
        case .animation:
            // Dừng animation khi chuyển từ tab Animation sang tab khác
            if isAnimating {
                if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                    if coordinator.animationLineView?.isAnimating == true {
                        print("Stopping animation when changing tabs")
                        coordinator.animationLineView?.stopAnimation()
                    }
                }
                isAnimating = false
            }
        default:
            break
        }
        
        // Cập nhật mode mới
        mode = newMode
        
        // Không cần clear map hoàn toàn, chỉ cập nhật các phần tử UI cần thiết
        print("Mode updated to \(newMode)")
    }
    
    // Restore the map state after style loading
    func restoreMapState() {
        // Khôi phục trạng thái dựa trên mode hiện tại
        print("Restoring map state for mode: \(mode)")
        
        if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
            DispatchQueue.main.async {
                switch self.mode {
                case .singlePoint:
                    // Hiển thị marker đã lưu nếu có
                    if let location = self.selectedLocation {
                        self.addMarker(at: location, title: "Selected Location")
                    }
                    
                case .wayPoint:
                    // Hiển thị lại các waypoints
                    self.showWaypoints()
                    
                case .cluster:
                    // Khởi tạo lại clusters
                    coordinator.clusterView?.setupClusters(on: self.mapViewManager.mapView)
                    
                case .animation:
                    // Khôi phục animation nếu có
                    if let route = self.currentRoute, let coordinates = route.coordinates, coordinates.count >= 2 {
                        coordinator.animationLineView?.allCoordinates = coordinates
                        coordinator.animationLineView?.addPolyline(to: self.mapViewManager.mapView.style!, mapview: self.mapViewManager.mapView)
                        if self.isAnimating {
                            coordinator.animationLineView?.animatePolyline()
                        }
                    } else {
                        print("Route does not have valid coordinates")
                    }
                    
                case .feature, .compare:
                    // Nothing special to restore
                    break
                }
            }
        }
    }
    
    // Hiển thị lại waypoints và route hiện tại
    private func showWaypoints() {
        for waypoint in waypoints {
            let marker = MLNPointAnnotation()
            marker.coordinate = waypoint
            marker.title = "Lat: \(waypoint.latitude), Lng: \(waypoint.longitude)"
            mapViewManager.mapView.addAnnotation(marker)
        }
        
        // Hiển thị route nếu có
        if let route = currentRoute {
            if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                // Lấy tọa độ đúng cách từ route
                if let coordinates = route.coordinates, coordinates.count >= 2 {
                    coordinator.mapRouteHandler?.calculateRoute(from: coordinates[0], to: coordinates[coordinates.count - 1])
                } else {
                    print("Route does not have valid coordinates")
                }
            }
        }
    }
    
    // Clear all waypoints
    func clearWaypoints() {
        // Remove waypoint annotations
        if let annotations = mapViewManager.mapView.annotations?.filter({ annotation in
            if let title = annotation.title {
                return ((title?.contains("Waypoint")) != nil) || ((title?.contains("Điểm")) != nil)
            }
            return false
        }) {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
        
        // Clear route overlays
        let overlays = mapViewManager.mapView.overlays
        mapViewManager.mapView.removeOverlays(overlays)
        
        // Clear data
        waypoints.removeAll()
        currentRoute = nil
        
        print("Waypoints and route cleared")
    }
    
    // Complete removal of map elements
    func clearMap() {
        print("⚠️ Complete map clearing is deprecated - use selective clearing instead")
        selectivelyUpdateMapForMode()
    }
    
    // Add marker handling
    func addMarker(at coordinate: CLLocationCoordinate2D, title: String?, retryCount: Int = 0) {
        print("MapViewModel - Adding marker at: \(coordinate.latitude), \(coordinate.longitude), styleLoaded: \(isStyleLoaded), mapReady: \(isMapReady), retry: \(retryCount)")
        
        // Store the location for future reference
        selectedLocation = coordinate
        
        // Tạo id duy nhất cho marker này dựa trên tọa độ
        let markerId = "\(coordinate.latitude),\(coordinate.longitude)"
        
        // Kiểm tra xem map đã sẵn sàng chưa
        if isStyleLoaded && isMapReady {
            // Add marker directly if map is ready
            mapViewManager.addMarker(at: coordinate, title: title)
            
            // Thông báo cập nhật
            let userInfo: [AnyHashable: Any] = [
                "coordinates": [coordinate.longitude, coordinate.latitude],
                "title": title ?? "Selected Location"
            ]
            NotificationCenter.default.post(name: NSNotification.Name("MarkerAdded"), object: nil, userInfo: userInfo)
        } else {
            // Queue marker for later if map isn't ready
            queuedMarkers[markerId] = (coordinate, title, 0)
            
            // Start processing queue if not already running
            if !isProcessingQueue {
                processQueuedMarkers()
            }
        }
    }
    
    // Process queued markers
    func processQueuedMarkers() {
        guard !queuedMarkers.isEmpty else {
            isProcessingQueue = false
            return
        }
        
        isProcessingQueue = true
        
        // Process each queued marker
        for (id, markerInfo) in queuedMarkers {
            let (coordinate, title, retryCount) = markerInfo
            
            if isStyleLoaded && isMapReady {
                // Add marker if map is ready
                mapViewManager.addMarker(at: coordinate, title: title)
                queuedMarkers.removeValue(forKey: id)
            } else if retryCount < maxRetryCount {
                // Increment retry count
                queuedMarkers[id] = (coordinate, title, retryCount + 1)
                
                // Retry later
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.processQueuedMarkers()
                }
                return
            } else {
                // Maximum retries reached, give up on this marker
                print("⚠️ Failed to add marker after \(maxRetryCount) retries: \(coordinate.latitude), \(coordinate.longitude)")
                queuedMarkers.removeValue(forKey: id)
            }
        }
        
        // Check if there are still queued markers to process
        if !queuedMarkers.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.processQueuedMarkers()
            }
        } else {
            isProcessingQueue = false
        }
    }
    
    // Center map on user location
    func centerOnUserLocation() {
        mapViewManager.centerOnUserLocation()
    }
    
    // Handle map tap
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        print("Map tapped at \(coordinate.latitude), \(coordinate.longitude)")
        
        switch mode {
        case .singlePoint:
            // Add marker and fetch address
            addMarker(at: coordinate, title: "Vị trí đã chọn")
            
            // Start geocoding
            let geocodingRepo = GeocodingRepository()
            geocodingRepo.fetchGeocoding(
                lat: String(format: "%.6f", coordinate.latitude),
                lng: String(format: "%.6f", coordinate.longitude)
            )
            
        case .wayPoint:
            // Handle waypoint logic (implemented in MapWayPointView)
            print("Waypoint tap handled by MapWayPointView")
            
        case .cluster:
            // Nothing specific for cluster mode
            break
            
        case .animation:
            // Nothing specific for animation mode
            break
            
        case .feature, .compare:
            // For feature mode, just add a marker
            addMarker(at: coordinate, title: "Feature Location")
        }
    }
    
    // Function to setup cluster points
    func setupClusterPoints() {
        // Tạo các điểm cluster ngẫu nhiên xung quanh vị trí trung tâm
        let centerCoordinate = MapUtils.getLatlng(idCountry: "vn") // Hoặc sử dụng country hiện tại
        // Tạo 50 điểm ngẫu nhiên trong bán kính 50km
        let points = generateRandomPoints(around: CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude).coordinate, count: 50, radiusInKm: 50)
        
        // Thêm các điểm vào bản đồ
        for (index, point) in points.enumerated() {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = point
            annotation.title = "Point \(index + 1)"
            mapViewManager.mapView.addAnnotation(annotation)
        }
    }
    
    // Helper method to generate random points
    private func generateRandomPoints(around center: CLLocationCoordinate2D, count: Int, radiusInKm: Double) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        
        for _ in 0..<count {
            // Tạo điểm ngẫu nhiên trong bán kính
            let radiusInDegrees = radiusInKm / 111.32 // 1 độ ~ 111.32km
            
            let u = Double.random(in: 0...1)
            let v = Double.random(in: 0...1)
            let w = radiusInDegrees * sqrt(u)
            let t = 2 * .pi * v
            let x = w * cos(t)
            let y = w * sin(t)
            
            let newLat = center.latitude + y
            let newLng = center.longitude + x / cos(center.latitude * .pi / 180)
            
            points.append(CLLocationCoordinate2D(latitude: newLat, longitude: newLng))
        }
        
        return points
    }
    
    // Function to add waypoint
    func addWaypoint(at coordinate: CLLocationCoordinate2D) {
        // Thêm waypoint vào danh sách
        waypoints.append(coordinate)
        // Thêm annotation
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Waypoint \(waypoints.count)"
        mapViewManager.mapView.addAnnotation(annotation)
        if waypoints.count >= 2 {
            updateRouteWithWaypoints()
        }
    }
    
    // Function to handle route calculation
    func updateRouteWithWaypoints() {
        // Implementation for route calculation
    }
    
    // Function to draw a route on the map
    func drawRoute(route: Route) {
        print("🛣️ Drawing route on map...")
        
        // Make sure we have coordinates for the route
        guard let coordinates = route.coordinates, coordinates.count > 0 else {
            print("⚠️ No coordinates in route")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Clear any existing route lines first
            self.clearRouteLines()
            
            // Draw the main route line
            if let style = self.mapViewManager.mapView.style {
                let source = MLNShapeSource(identifier: "route-source", shape: MLNPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count)), options: nil)
                
                // Add source to the map
                style.addSource(source)
                
                // Create a line layer for the route
                let routeLayer = MLNLineStyleLayer(identifier: "route-layer", source: source)
                routeLayer.lineColor = NSExpression(forConstantValue: UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 1))
                routeLayer.lineWidth = NSExpression(forConstantValue: 5)
                routeLayer.lineCap = NSExpression(forConstantValue: "round")
                routeLayer.lineJoin = NSExpression(forConstantValue: "round")
                
                // Add the line layer to the map
                style.addLayer(routeLayer)
                
                // Also add a casing layer to make the route more visible
                let casingLayer = MLNLineStyleLayer(identifier: "route-casing-layer", source: source)
                casingLayer.lineColor = NSExpression(forConstantValue: UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 0.3))
                casingLayer.lineWidth = NSExpression(forConstantValue: 8)
                casingLayer.lineCap = NSExpression(forConstantValue: "round")
                casingLayer.lineJoin = NSExpression(forConstantValue: "round")
                
                // Insert the casing layer below the route layer for visual effect
                style.insertLayer(casingLayer, below: routeLayer)
                
                print("✅ Route line added to map")
                
                // Adjust camera to show the entire route
                self.fitCameraToRoute(coordinates: coordinates)
            } else {
                print("⚠️ Map style not available")
            }
        }
    }
    
    // Clear all route lines from the map
    private func clearRouteLines() {
        print("🧹 Clearing route lines")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let style = self.mapViewManager.mapView.style else { return }
            
            // Remove route layers if they exist
            if let routeLayer = style.layer(withIdentifier: "route-layer") {
                style.removeLayer(routeLayer)
            }
            
            if let casingLayer = style.layer(withIdentifier: "route-casing-layer") {
                style.removeLayer(casingLayer)
            }
            
            // Remove route source if it exists
            if let source = style.source(withIdentifier: "route-source") {
                style.removeSource(source)
            }
        }
    }
    
    // Adjust camera to show the entire route
    private func fitCameraToRoute(coordinates: [CLLocationCoordinate2D]) {
        print("🔍 Fitting camera to route")
        
        guard !coordinates.isEmpty else {
            print("⚠️ Cannot fit camera to empty coordinates array")
            return
        }
        
        // Create a bounds that includes all coordinates
        // Calculate bounds manually
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0
        
        // Create southwest and northeast coordinates
        let southwest = CLLocationCoordinate2D(latitude: minLat, longitude: minLng)
        let northeast = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng)
        
        // Create bounds using sw/ne initializer
        let boundingBox = MLNCoordinateBounds(sw: southwest, ne: northeast)
        
        // Add some padding to the edges
        let insets = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
        
        // Tell the map to fit these bounds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.mapViewManager.mapView.setVisibleCoordinateBounds(boundingBox, edgePadding: insets, animated: true)
        }
    }
}

// MARK: - MapViewController
struct MapViewController: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = viewModel.mapViewManager.mapView
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Xử lý cập nhật nếu cần
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate, UIGestureRecognizerDelegate {
        var parent: MapViewController
        var tapGesture: UITapGestureRecognizer?
        var mapView: MLNMapView?
        
        // Thay đổi kiểu của clusterView
        var clusterView: ClusterManager?
        // Sửa tên của routeHandler để tránh xung đột
        var mapRouteHandler: MapRouteHandler?
        
        // Tham chiếu đến animation line view
        var animationLineView: PolylineView?
        
        var isEnabled = false
        var isAnimating = false
        var currentMode: MapMode = .singlePoint
        
        init(_ parent: MapViewController) {
            self.parent = parent
            super.init()
            
            // Khởi tạo routeHandler và clusterView
            self.mapRouteHandler = MapRouteHandler(identifier: "main")
            self.clusterView = ClusterManager()
        }
        
        // MLNMapViewDelegate
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            self.mapView = mapView
            
            // Thiết lập các chức năng dựa vào mode
            setupForCurrentMode()
        }
        
        private func setupForCurrentMode() {
            // Xóa các gesture cũ
            if let oldGesture = tapGesture {
                mapView?.removeGestureRecognizer(oldGesture)
                tapGesture = nil
            }
            
            // Cập nhật mode
            currentMode = parent.viewModel.mode
            
            // Thiết lập dựa vào mode mới
            switch currentMode {
            case .singlePoint:
                setupSinglePointMode()
            case .wayPoint:
                setupWaypointMode()
            case .cluster:
                setupClusterMode()
            case .animation:
                setupAnimationMode()
            case .feature:
                setupFeatureMode()
            case .compare:
                setupCompareMode() // Thêm case để switch được exhaustive
            }
        }
        
        // Thêm phương thức này để switch được exhaustive
        private func setupCompareMode() {
            // Xử lý cho chế độ compare
        }
        
        // Sửa setupClusterMode để sử dụng ClusterManager thay vì clusterView.setupCluster()
        private func setupClusterMode() {
            // Khởi tạo và cấu hình ClusterManager
            self.clusterView?.setupClusters(on: mapView)
            
            // Gọi setupClusterPoints trên viewModel
            parent.viewModel.setupClusterPoints()
        }
        
        private func setupSinglePointMode() {
            guard let mapView = mapView else { return }
            
            // Thiết lập tap gesture cho single point
            let newTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSinglePointTap(_:)))
            mapView.addGestureRecognizer(newTapGesture)
            self.tapGesture = newTapGesture
        }
        
        private func setupWaypointMode() {
            guard let mapView = mapView else { return }
            
            // Thiết lập tap gesture cho waypoint
            let newTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleWaypointTap(_:)))
            mapView.addGestureRecognizer(newTapGesture)
            self.tapGesture = newTapGesture
        }
        
        func setupAnimationMode() {
            // Thiết lập tuyến đường và animation
            if let route = parent.viewModel.currentRoute, let coordinates = route.coordinates {
                setupAnimationRoute(with: coordinates)
            } else {
                createSampleRoute()
            }
        }
        
        private func setupFeatureMode() {
            // Không cần thiết lập đặc biệt cho feature mode
        }
        
        private func createSampleRoute() {
            let latLng = MapUtils.getLatlng(idCountry: "vn") // Có thể thay thế bằng country từ parent.viewModel
            let originCoordinate = latLng.toCLLocationCoordinate2D()
            let destinationCoordinate = CLLocationCoordinate2D(
                latitude: originCoordinate.latitude + 0.05,
                longitude: originCoordinate.longitude + 0.05
            )
            
            // Tạo mảng tọa độ
            let coordinates = [originCoordinate, destinationCoordinate]
            
            // Thiết lập animation route
            setupAnimationRoute(with: coordinates)
        }
        
        // Function to handle route calculation
        func setupAnimationRoute(with coordinates: [CLLocationCoordinate2D]) {
            // Xóa animation line view cũ
            if let oldAnimationLine = animationLineView {
                oldAnimationLine.stopAnimation()
            }
            
            // Tạo animation line view mới
            let polylineView = PolylineView(coordinates: coordinates)
            if let style = mapView?.style, let mapView = mapView {
                polylineView.addPolyline(to: style, mapview: mapView)
            }
            
            // Lưu tham chiếu
            animationLineView = polylineView
        }
        
        // MARK: - Gesture Recognizer Handlers
        
        @objc func handleSinglePointTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView, parent.viewModel.mode == .singlePoint else { return }
            
            // Lấy vị trí chạm và chuyển thành tọa độ
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Đặt marker và gửi yêu cầu geocoding
            parent.viewModel.addMarker(at: coordinate, title: "Vị trí đã chọn")
        }
        
        @objc func handleWaypointTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView, parent.viewModel.mode == .wayPoint else { return }
            
            // Lấy vị trí chạm và chuyển thành tọa độ
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Thêm waypoint
            parent.viewModel.addWaypoint(at: coordinate)
        }
        
        // UIGestureRecognizerDelegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Cho phép xử lý cùng lúc với các gesture khác (như pinch để zoom)
            return true
        }
    }
}

// MARK: - Route Handler class
class MapRouteHandler {
    // Các hàm xử lý tuyến đường
    
    init(identifier: String = "default") {
        // Initialize with identifier
    }
    
    func calculateRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        // Xử lý tính toán tuyến đường
        print("Calculating route from \(origin) to \(destination)")
    }
    
    // Thêm phương thức addRoute
    func addRoute(_ route: Route) {
        if let coordinates = route.coordinates {
            print("Adding route with \(coordinates.count) coordinates")
            // Xử lý thêm route vào map
        }
    }
}

// MARK: - Utility Extensions

// Helper function to convert LatLng to CLLocationCoordinate2D
func mapUtilsLatLngToCoordinate(_ latLng: LatLng) -> CLLocationCoordinate2D {
    return latLng.toCLLocationCoordinate2D()
}

// MARK: - ClusterManager class
class ClusterManager {
    // Class quản lý clustering
    
    // Thêm phương thức setupClusters với tham số mapView
    func setupClusters(on mapView: MLNMapView?) {
        guard let mapView = mapView else { return }
        
        // Cấu hình các tham số cluster nếu cần
        print("Setting up clusters on map view")
        
        // Có thể thêm code để cấu hình cluster ở đây
    }
}


