// MARK: - User Location Methods
public func getUserLocation() -> CLLocation? {
    guard let mapView = self.mapView else {
        print("❌ MapView not initialized")
        return nil
    }
    
    if let userLocation = mapView.userLocation?.location {
        print("✅ Got user location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        return userLocation
    } else {
        print("⚠️ User location not available")
        return nil
    }
}

// MARK: - Route and Polyline Methods
public func addPolyline(coordinates: [CLLocationCoordinate2D]) {
    guard let mapView = self.mapView else {
        print("❌ MapView not initialized")
        return
    }
    
    print("🗺️ Adding polyline with \(coordinates.count) points")
    
    // Remove existing polylines first
    removeAllPolylines()
    
    let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
    
    // Create source for the polyline if it doesn't exist
    if mapView.style?.source(withIdentifier: "route-source") == nil {
        let source = MLNShapeSource(identifier: "route-source", shape: polyline, options: nil)
        mapView.style?.addSource(source)
    } else {
        // Update existing source
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MLNShapeSource {
            source.shape = polyline
        }
    }
    
    // Add or update the layer if needed
    if mapView.style?.layer(withIdentifier: "route-layer") == nil {
        let layer = MLNLineStyleLayer(identifier: "route-layer", source: "route-source")
        layer.lineColor = NSExpression(forConstantValue: UIColor.blue)
        layer.lineWidth = NSExpression(forConstantValue: 4.0)
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineJoin = NSExpression(forConstantValue: "round")
        
        mapView.style?.addLayer(layer)
    }
    
    // Fit the map to the polyline with padding
    let padding = UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40)
    mapView.setVisibleCoordinates(coordinates, count: UInt(coordinates.count), edgePadding: padding, animated: true)
    
    print("✅ Polyline added to map")
}

public func removeAllPolylines() {
    guard let mapView = self.mapView, let style = mapView.style else {
        print("❌ MapView or style not initialized")
        return
    }
    
    if style.layer(withIdentifier: "route-layer") != nil {
        style.removeLayer(withIdentifier: "route-layer")
    }
    
    if style.source(withIdentifier: "route-source") != nil {
        style.removeSource(withIdentifier: "route-source")
    }
    
    print("🧹 All polylines removed from map")
} 