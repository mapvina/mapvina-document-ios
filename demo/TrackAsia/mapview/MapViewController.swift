//
//  MapViewController.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//  Updated with combined utils functionality
//

import Foundation
import SwiftUI
import TrackAsia
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapKit
import Alamofire
import Combine


// MARK: - MapViewMode
enum MapViewMode {
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
    @Published var mode: MapViewMode = .singlePoint
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var currentRoute: Route?
    @Published var isAnimating: Bool = false
    @Published var addresses: [AddressModel] = []
    @Published var isStyleLoaded: Bool = false
    @Published var isMapReady: Bool = false
    private var geocodingRepository = GeocodingRepository()
    private var addressRepository = AddressRepository()
    private var styleLoadingTask: DispatchWorkItem?
    
    init() {
        setupMapObservers()
    }
    
    private func setupMapObservers() {
        // Add observers for map state changes if needed
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                            object: nil,
                                            queue: .main) { [weak self] _ in
            self?.handleAppForeground()
        }
    }
    
    private func handleAppForeground() {
        // Refresh map when app comes to foreground
        if let country = UserDefaults.standard.string(forKey: "selectedCountry") {
            updateMap(selectedCountry: country)
        }
    }
    
    func prepareForModeChange() {
        // Clear existing state before mode change
        clearMap()
        isStyleLoaded = false
        isMapReady = false
    }
    
    func addMarker(at coordinate: CLLocationCoordinate2D, title: String?) {
        guard isStyleLoaded && isMapReady else {
            // Queue the marker addition for when the map is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addMarker(at: coordinate, title: title)
            }
            return
        }
        mapViewManager.addMarker(at: coordinate, title: title)
    }

    func moveCamera(to coordinate: CLLocationCoordinate2D, zoom: Double) {
        guard isStyleLoaded && isMapReady else {
            // Queue the camera movement for when the map is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.moveCamera(to: coordinate, zoom: zoom)
            }
            return
        }
        mapViewManager.moveCamera(to: coordinate, zoom: zoom)
    }

    func centerOnUserLocation() {
        guard isStyleLoaded && isMapReady else {
            // Queue the centering for when the map is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.centerOnUserLocation()
            }
            return
        }
        mapViewManager.centerOnUserLocation()
    }

    func updateMap(selectedCountry: String) {
        // Cancel any pending style loading task
        styleLoadingTask?.cancel()
        
        let newTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Reset states
            self.isStyleLoaded = false
            self.isMapReady = false
            
            // Clear existing annotations and overlays
            self.clearMap()
            
            // Update the map style and center
            let styleUrl = MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
            let location = MapUtils.getLatlng(idCountry: selectedCountry)
            let zoom = MapUtils.zoom(idCountry: selectedCountry)
            
            // Create new camera position
            let newCenter = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            
            // Update map properties
            DispatchQueue.main.async {
                // Update style URL first
                self.mapViewManager.mapView.styleURL = URL(string: styleUrl)
                
                // Wait for style to load before updating camera
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.mapViewManager.mapView.setCenter(newCenter, zoomLevel: zoom, animated: true)
                    
                    // Set map as ready after camera update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.isMapReady = true
                        
                        // Restore state based on mode
                        self.restoreMapState()
                    }
                }
            }
        }
        
        styleLoadingTask = newTask
        DispatchQueue.main.async(execute: newTask)
    }
    
    func restoreMapState() {
        guard isStyleLoaded && isMapReady else { return }
        
        switch mode {
        case .singlePoint:
            if let location = selectedLocation {
                addMarker(at: location, title: "Selected Location")
            }
            
        case .wayPoint:
            for (index, waypoint) in waypoints.enumerated() {
                if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                    WaypointView.addWaypoints(mapView: mapViewManager.mapView, waypoints: [Waypoint(coordinate: waypoint)])
                }
            }
            if let route = currentRoute {
                if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                    coordinator.routeHandler?.addRoute(route)
                }
            }
            
        case .cluster:
            if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                coordinator.clusterView?.setupCluster()
            }
            
        case .animation:
            if let route = currentRoute, let coordinates = route.coordinates {
                if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                    coordinator.animationLineView?.allCoordinates = coordinates
                    coordinator.animationLineView?.addPolyline(to: mapViewManager.mapView.style!, mapview: mapViewManager.mapView)
                    if isAnimating {
                        coordinator.animationLineView?.animatePolyline()
                    }
                }
            }
            
        case .feature, .compare:
            if let location = selectedLocation {
                addMarker(at: location, title: "Selected Location")
            }
        }
    }
    
    // Mode-specific functions
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        switch mode {
        case .singlePoint:
            selectedLocation = coordinate
            addMarker(at: coordinate, title: "Selected Location")
            // Fetch address for the selected location
            geocodingRepository.fetchGeocoding(
                lat: String(coordinate.latitude),
                lng: String(coordinate.longitude)
            )
            
        case .wayPoint:
            waypoints.append(coordinate)
            if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                WaypointView.addWaypoints(mapView: mapViewManager.mapView, waypoints: [Waypoint(coordinate: coordinate)])
                
                // If we have two or more waypoints, request a route
                if waypoints.count >= 2 {
                    let origin = waypoints[waypoints.count - 2]
                    let destination = waypoints[waypoints.count - 1]
                    coordinator.routeHandler?.requestRoute(from: origin, to: destination) { [weak self] route in
                        if let route = route {
                            self?.currentRoute = route
                            coordinator.routeHandler?.addRoute(route)
                        }
                    }
                }
            }
            
        case .cluster:
            if let clusterView = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                // Add cluster point functionality if needed
            }
            
        case .animation:
            if let animationView = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
                if let route = currentRoute, let coordinates = route.coordinates {
                    animationView.animationLineView?.allCoordinates = coordinates
                    animationView.animationLineView?.addPolyline(to: mapViewManager.mapView.style!, mapview: mapViewManager.mapView)
                    isAnimating = true
                    animationView.animationLineView?.animatePolyline()
                } else {
                    // If no route exists, create a simple animation path with single point
                    animationView.animationLineView?.allCoordinates = [coordinate]
                    animationView.animationLineView?.addPolyline(to: mapViewManager.mapView.style!, mapview: mapViewManager.mapView)
                    isAnimating = true
                    animationView.animationLineView?.animatePolyline()
                }
            }
            
        case .feature:
            selectedLocation = coordinate
            addMarker(at: coordinate, title: "Feature Point")
            // Search for nearby features
            addressRepository.fetchAddresses(with: "\(coordinate.latitude),\(coordinate.longitude)")
            
        case .compare:
            selectedLocation = coordinate
            addMarker(at: coordinate, title: "Selected Location")
        }
    }
    
    func clearMap() {
        if let coordinator = mapViewManager.mapView.delegate as? MapViewController.Coordinator {
            // Clear waypoints using static method
            if let mapView = coordinator.waypointView?.mapView {
                if let annotations = mapView.annotations {
                    mapView.removeAnnotations(annotations)
                }
            }
            
            waypoints.removeAll()
            currentRoute = nil
            selectedLocation = nil
            isAnimating = false
            
            // Remove all annotations and overlays from main map
            if let annotations = mapViewManager.mapView.annotations {
                mapViewManager.mapView.removeAnnotations(annotations)
            }
            
            // Remove overlays - no need for optional binding since overlays is not optional
            let overlays = mapViewManager.mapView.overlays
            mapViewManager.mapView.removeOverlays(overlays)
            
            // Reset animation view if needed
            coordinator.animationLineView = AnimationLineView()
        }
    }
    
    func searchAddress(_ query: String) {
        addressRepository.fetchAddresses(with: query)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        styleLoadingTask?.cancel()
    }
}

// MARK: - MapViewController
struct MapViewController: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        viewModel.mapViewManager.mapView.delegate = context.coordinator
        return viewModel.mapViewManager.mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
        uiView.delegate = context.coordinator
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapViewController
        var animationLineView: AnimationLineView?
        var clusterView: ClusterView?
        var routeHandler: RouteHandler?
        var waypointView: WaypointView?
        
        init(parent: MapViewController) {
            self.parent = parent
            super.init()
            setupViews()
        }
        
        private func setupViews() {
            let mapView = parent.viewModel.mapViewManager.mapView
            animationLineView = AnimationLineView()
            clusterView = ClusterView(mapView: mapView)
            routeHandler = RouteHandler(mapView: mapView)
            waypointView = WaypointView(mapView: mapView)
            
            // Add tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
            mapView.addGestureRecognizer(tapGesture)
        }
        
        @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: parent.viewModel.mapViewManager.mapView)
            let coordinate = parent.viewModel.mapViewManager.mapView.convert(point, toCoordinateFrom: parent.viewModel.mapViewManager.mapView)
            parent.viewModel.handleMapTap(at: coordinate)
        }
        
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            parent.viewModel.isStyleLoaded = true
            
            // Restore map state after style is loaded
            parent.viewModel.restoreMapState()
        }
        
        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            if let point = annotation as? MLNPointAnnotation {
                parent.viewModel.mapViewManager.invokeOnLocationSelected(
                    coordinate: point.coordinate,
                    name: point.title ?? ""
                )
                
                // Handle selection based on mode
                switch parent.viewModel.mode {
                case .wayPoint:
                    // Use the last waypoint from viewModel instead
                    if let lastWaypoint = parent.viewModel.waypoints.last {
                        routeHandler?.requestRoute(from: lastWaypoint, to: point.coordinate) { [weak self] route in
                            if let route = route {
                                self?.routeHandler?.addRoute(route)
                            }
                        }
                    }
                case .animation:
                    if let route = routeHandler?.currentRoute, let coordinates = route.coordinates {
                        animationLineView?.allCoordinates = coordinates
                        animationLineView?.addPolyline(to: mapView.style!, mapview: mapView)
                        animationLineView?.animatePolyline()
                    }
                default:
                    break
                }
            }
        }
    }
}
