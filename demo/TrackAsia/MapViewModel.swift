import SwiftUI
import TrackAsia
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation

class MapViewModel: ObservableObject {
    // MARK: - Properties
    @Published var mode: MapMode = .singlePoint
    @Published var isStyleLoaded: Bool = false
    @Published var currentCountry: String = "vn"
    @Published var isAnimating: Bool = false
    @Published var currentRoute: Route?
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var currentTabIndex: Int?
    @Published var showCompareView: Bool = false
    @Published var searchText: String = ""
    @Published var isMapReady: Bool = false
    @Published var featureOptions: [String: Bool] = [
        "showMarkers": false,
        "showPolyline": false,
        "showPolygon": false,
        "showHeatmap": false,
        "showBuildings3D": false
    ]
    
    // Navigation-specific properties
    @Published var navigationMode: NavigationMode = .planning
    @Published var startPoint: CLLocationCoordinate2D?
    @Published var endPoint: CLLocationCoordinate2D?
    
    // Callback for map taps
    var onMapTapped: ((CLLocationCoordinate2D) -> Void)?
    
    var mapViewManager = MapViewManager()
    
    // MARK: - Initialization
    init() {
        setupMapView()
        configureURLSessionTimeouts()
    }
    
    // MARK: - Setup Methods
    private func setupMapView() {
        mapViewManager.setupMapView()
    }
    
    // Cấu hình timeout cho các yêu cầu mạng
    private func configureURLSessionTimeouts() {
        // Tăng thời gian timeout cho các yêu cầu tài nguyên
        URLSessionConfiguration.default.timeoutIntervalForResource = 60.0 // 60 giây
        URLSessionConfiguration.default.timeoutIntervalForRequest = 60.0 // 60 giây
        
        // Đảm bảo URL Session sử dụng cấu hình mới
        URLSession.shared.reset {
            print("🔄 URLSession đã được cấu hình lại với timeout dài hơn")
        }
    }
    
    // MARK: - Map State Management
    func updateMap(selectedCountry: String) {
        // Cập nhật quốc gia
        currentCountry = selectedCountry
        
        // Cập nhật style và camera
        let latLng = MapUtils.getLatlng(idCountry: selectedCountry)
        // Chuyển đổi từ LatLng sang CLLocationCoordinate2D
        let coordinate = latLng.toCLLocationCoordinate2D()
        mapViewManager.moveCamera(to: coordinate, zoom: 12)
    }
    
    func restoreMapState() {
        // Khôi phục trạng thái bản đồ sau khi style đã tải
        updateMap(selectedCountry: currentCountry)
    }
    
    // MARK: - Mode Management
    func updateMode(_ selectedMode: MapMode) {
        if mode != selectedMode {
            print("🔄 Đang thay đổi chế độ từ \(mode) sang \(selectedMode)")
            
            // Xử lý khi thoát khỏi chế độ hiện tại
            switch mode {
            case .navigation:
                waypoints.removeAll()
                mapViewManager.removeAllPolylines()
                clearAllAnnotations()
            case .feature:
                prepareFeatureMode()
            case .compare:
                hideCompareView()
            case .animation:
                stopAnimating()
            default:
                break
            }
            
            // Reset onMapTapped callback khi chuyển mode
            print("🔄 Resetting onMapTapped callback in MapViewModel")
            onMapTapped = nil
            
            // Cập nhật chế độ mới
            mode = selectedMode
            
            // Xử lý khi vào chế độ mới
            switch selectedMode {
            case .navigation:
                mapViewManager.addMapLongPressGesture()
            case .animation:
                createSampleRoute()
            case .heatmap:
                setupHeatmap()
            case .cluster:
                setupClusterPoints()
            case .compare:
                setupCompareView()
            default:
                break
            }
            
            print("✅ Đã chuyển sang chế độ: \(selectedMode)")
        }
    }
    
    func prepareForModeChange() {
        // Clean up resources from previous mode
        clearAllAnnotations()
        stopAnimating()
        
        // Xóa các dữ liệu đặc biệt
        if mode == .wayPoint {
            waypoints.removeAll()
        }
        
        // Reset compare view status if leaving compare mode
        if mode == .compare {
            showCompareView = false
        }
    }
    
    func setupForCurrentMode() {
        // Thiết lập dựa vào chế độ mới
        switch mode {
        case .singlePoint:
            // Không cần thiết lập bổ sung
            break
        case .wayPoint:
            // Xóa waypoints
            waypoints.removeAll()
        case .cluster:
            setupClusterPoints()
        case .animation:
            setupAnimationRoute()
        case .feature:
            prepareFeatureMode()
        case .compare:
            // Setup compare mode
            break
        }
    }
    
    // MARK: - Feature-specific Methods
    
    // SinglePoint Mode
    func addMarker(at coordinate: CLLocationCoordinate2D, title: String) {
        // Xóa marker cũ (nếu ở chế độ single point)
        if mode == .singlePoint {
            clearAllAnnotations()
        }
        
        // Thêm marker mới
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapViewManager.mapView.addAnnotation(annotation)
        
        // Di chuyển camera đến vị trí marker
        mapViewManager.moveCamera(to: coordinate, zoom: 14)
    }
    
    // WayPoint Mode
    func addWaypoint(at coordinate: CLLocationCoordinate2D) {
        // Thêm waypoint vào danh sách
        waypoints.append(coordinate)
        
        // Thêm annotation
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Waypoint \(waypoints.count)"
        mapViewManager.mapView.addAnnotation(annotation)
        
        // Nếu có từ 2 điểm trở lên, vẽ đường nối
        if waypoints.count >= 2 {
            drawPolylineBetweenWaypoints()
        }
    }
    
    func drawPolylineBetweenWaypoints() {
        // Xóa polyline cũ
        mapViewManager.removeAllPolylines()
        
        // Vẽ polyline mới
        mapViewManager.addPolyline(coordinates: waypoints)
    }
    
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
        mapViewManager.removeAllPolylines()
        
        // Clear data
        waypoints.removeAll()
        currentRoute = nil
        startPoint = nil
        endPoint = nil
        
        print("Waypoints and route cleared")
    }
    
    // Cluster Mode
    func setupClusterPoints() {
        print("🔄 Setting up cluster points in MapViewModel")
        
        // Avoid adding random points if we're using ClusterView
        // Instead, let ClusterView handle the data from GeoJSON
        
        // Center the map on the selected country
        let latLng = MapUtils.getLatlng(idCountry: currentCountry)
        let centerCoordinate = latLng.toCLLocationCoordinate2D()
        
        // Set an appropriate zoom level for viewing clusters
        mapViewManager.moveCamera(to: centerCoordinate, zoom: 8)
        print("📍 Centered map for cluster view at \(centerCoordinate.latitude), \(centerCoordinate.longitude), zoom: 8")
    }
    
    // Animation Mode
    func setupAnimationRoute() {
        // Tạo tuyến đường mẫu nếu chưa có
        if currentRoute == nil {
            createSampleRoute()
        }
        
        // Hiển thị tuyến đường nếu có
        if let route = currentRoute, let coordinates = route.coordinates {
            mapViewManager.addAnimationPolyline(coordinates: coordinates)
        }
    }
    
    func createSampleRoute() {
        let latLng = MapUtils.getLatlng(idCountry: currentCountry)
        let originCoordinate = latLng.toCLLocationCoordinate2D()
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: originCoordinate.latitude + 0.05,
            longitude: originCoordinate.longitude + 0.05
        )
        
        let origin = Waypoint(coordinate: originCoordinate)
        let destination = Waypoint(coordinate: destinationCoordinate)
        
        // Thêm explicit type annotation để tránh lỗi heterogeneous collection
        let coordinatesArray: [[Double]] = [
            [originCoordinate.longitude, originCoordinate.latitude], 
            [destinationCoordinate.longitude, destinationCoordinate.latitude]
        ]
        
        // Tạo tuyến đường mẫu
        currentRoute = Route(
            json: ["coordinates": coordinatesArray],
            waypoints: [origin, destination],
            options: NavigationRouteOptions(waypoints: [origin, destination])
        )
    }
    
    func startAnimating() {
        self.isAnimating = true
        mapViewManager.startAnimatingPolyline()
    }
    
    func stopAnimating() {
        self.isAnimating = false
        mapViewManager.stopAnimatingPolyline()
    }
    
    // Feature Mode
    func prepareFeatureMode() {
        // Xóa tất cả đối tượng hiện tại
        clearAllAnnotations()
        mapViewManager.removeAllPolylines()
    }
    
    func addFeatureMarkers() {
        // Thêm markers mẫu
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662), // Ho Chi Minh City
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866)  // Hue
        ]
        
        for (index, location) in locations.enumerated() {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = location
            annotation.title = "Feature Location \(index + 1)"
            mapViewManager.mapView.addAnnotation(annotation)
        }
    }
    
    func addFeaturePolyline() {
        // Thêm polyline mẫu
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866), // Hue
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662)  // Ho Chi Minh City
        ]
        
        mapViewManager.addPolyline(coordinates: locations)
    }
    
    func addFeaturePolygon() {
        // Thêm polygon mẫu
        let locations = [
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444), // Hanoi
            CLLocationCoordinate2D(latitude: 16.463714, longitude: 107.590866), // Hue
            CLLocationCoordinate2D(latitude: 10.823099, longitude: 106.629662), // Ho Chi Minh City
            CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444)  // Đóng polygon bằng cách lặp lại điểm đầu tiên
        ]
        
        mapViewManager.addPolygon(coordinates: locations)
    }
    
    // MARK: - Compare Mode
    
    func setupCompareView() {
        // Hiển thị chế độ so sánh
        showCompareView = true
        
        // Nếu cần thêm cấu hình đặc biệt cho chế độ so sánh
        if let currentCoord = mapViewManager.mapView.userLocation?.coordinate, 
           CLLocationCoordinate2DIsValid(currentCoord) {
            // Sử dụng vị trí người dùng nếu có
            mapViewManager.moveCamera(to: currentCoord, zoom: 14)
        } else {
            // Nếu không có vị trí người dùng, sử dụng vị trí mặc định
            let latLng = MapUtils.getLatlng(idCountry: currentCountry)
            mapViewManager.moveCamera(to: latLng.toCLLocationCoordinate2D(), zoom: 14)
        }
    }
    
    func hideCompareView() {
        // Implementation for hiding the compare view
        showCompareView = false
    }
    
    // MARK: - Location Services
    func centerOnUserLocation() {
        print("📍 Attempting to center on user location")
        
        if let userLocation = self.mapViewManager.getUserLocation() {
            print("✅ Found user location at: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            self.mapViewManager.moveCamera(to: userLocation.coordinate, zoom: 14)
        } else {
            // Default to a location in Hanoi if user location isn't available
            print("⚠️ No user location available, defaulting to Hanoi")
            let hanoi = CLLocationCoordinate2D(latitude: 21.028511, longitude: 105.854444)
            self.mapViewManager.moveCamera(to: hanoi, zoom: 12)
        }
    }
    
    // MARK: - Map Tap Handlers
    func handleSinglePointTap(at coordinate: CLLocationCoordinate2D) {
        // Xử lý tap trong chế độ single point
        if mode == .singlePoint {
            addMarker(at: coordinate, title: "Vị trí đã chọn")
        }
    }
    
    func handleWaypointTap(at coordinate: CLLocationCoordinate2D) {
        print("📍 Adding waypoint at: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Add the coordinate to the waypoints array
        waypoints.append(coordinate)
        
        // Add a marker on the map for this waypoint
        addMarker(at: coordinate, title: "Waypoint \(waypoints.count)")
        
        // If we have 2+ waypoints, we can potentially draw a route
        if waypoints.count >= 2 {
            print("✅ Now have \(waypoints.count) waypoints, can calculate route")
        }
    }
    
    func handleClusterTap(at coordinate: CLLocationCoordinate2D) {
        // Xử lý tap trong chế độ cluster
        print("Tap in cluster mode at: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func handleAnimationTap(at coordinate: CLLocationCoordinate2D) {
        // Xử lý tap trong chế độ animation
        print("Tap in animation mode at: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    func handleFeatureTap(at coordinate: CLLocationCoordinate2D) {
        // Xử lý tap trong chế độ feature
        addMarker(at: coordinate, title: "Feature Location")
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        // Thực hiện geocoding ngược để lấy địa chỉ
        print("Reverse geocoding at: \(coordinate.latitude), \(coordinate.longitude)")
        // Thêm code geocoding thực tế ở đây nếu cần
    }
    
    func requestUserLocation() {
        // Yêu cầu vị trí người dùng
        centerOnUserLocation()
    }
    
    func searchLocation(query: String) {
        // Tìm kiếm địa điểm
        print("Searching for location: \(query)")
        // Thêm code tìm kiếm thực tế ở đây nếu cần
    }
    
    // MARK: - Helper Methods
    private func clearAllAnnotations() {
        if let annotations = mapViewManager.mapView.annotations {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
    }
    
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
    
    // Helper method to clear the map (annotations, polylines, etc.)
    func clearMap() {
        clearAllAnnotations()
        mapViewManager.removeAllPolylines()
    }
    
    // MARK: - Feature Management
    func toggleFeatureOption(_ option: String) {
        featureOptions[option] = !(featureOptions[option] ?? false)
        
        // Thực hiện các hành động cụ thể dựa trên tùy chọn
        switch option {
        case "showMarkers":
            if featureOptions[option] == true {
                addFeatureMarkers()
            } else {
                clearAllAnnotations()
            }
        case "showPolyline":
            if featureOptions[option] == true {
                addFeaturePolyline()
            } else {
                mapViewManager.removeAllPolylines()
            }
        case "showPolygon":
            if featureOptions[option] == true {
                addFeaturePolygon()
            } else {
                // Xóa polygon nếu cần
            }
        case "showHeatmap":
            if featureOptions[option] == true {
                // Thêm mã hiển thị heatmap
            } else {
                // Ẩn heatmap
            }
        case "showBuildings3D":
            if featureOptions[option] == true {
                // Hiển thị tòa nhà 3D
            } else {
                // Ẩn tòa nhà 3D
            }
        case "showCompare":
            // Được xử lý riêng trong MapFeatureView
            break
        default:
            break
        }
    }
    
    // MARK: - Waypoint Management Methods

    // Phương thức mới với tên hoàn toàn khác để tránh xung đột
    public func markStartLocation(at coordinate: CLLocationCoordinate2D, withTitle title: String) {
        print("Đang đánh dấu điểm đi tại: \(coordinate.latitude), \(coordinate.longitude)")
        // Remove existing start point if any
        if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đi" }) {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
        
        // Set the new start point
        self.startPoint = coordinate
        
        // Add an annotation for the start point
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapViewManager.mapView.addAnnotation(annotation)
        
        // Move camera to this point
        mapViewManager.moveCamera(to: coordinate, zoom: 14)
    }
    
    public func markEndLocation(at coordinate: CLLocationCoordinate2D, withTitle title: String) {
        print("Đang đánh dấu điểm đến tại: \(coordinate.latitude), \(coordinate.longitude)")
        // Remove existing end point if any
        if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đến" }) {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
        
        // Set the new end point
        self.endPoint = coordinate
        
        // Add an annotation for the end point
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapViewManager.mapView.addAnnotation(annotation)
        
        // If we have both start and end, make sure to show both
        if startPoint != nil && endPoint != nil {
            // Could add logic to fit both points in view
        }
    }
    
    // MARK: - Navigation Methods
    
    public func addStartMarker(coordinate: CLLocationCoordinate2D, title: String) {
        // Remove existing start point if any
        if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đi" }) {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
        
        // Set the new start point
        self.startPoint = coordinate
        
        // Add an annotation for the start point
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapViewManager.mapView.addAnnotation(annotation)
        
        // Move camera to this point
        mapViewManager.moveCamera(to: coordinate, zoom: 14)
    }
    
    public func addEndMarker(coordinate: CLLocationCoordinate2D, title: String) {
        // Remove existing end point if any
        if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đến" }) {
            mapViewManager.mapView.removeAnnotations(annotations)
        }
        
        // Set the new end point
        self.endPoint = coordinate
        
        // Add an annotation for the end point
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        mapViewManager.mapView.addAnnotation(annotation)
        
        // If we have both start and end, make sure to show both
        if startPoint != nil && endPoint != nil {
            // Could add logic to fit both points in view
        }
    }
    
    public func setStartPoint(coordinate: CLLocationCoordinate2D, title: String) {
        // Chuyển hướng sang phương thức mới để tránh xung đột với @Published
        addStartMarker(coordinate: coordinate, title: title)
    }
    
    public func setEndPoint(coordinate: CLLocationCoordinate2D, title: String) {
        // Chuyển hướng sang phương thức mới để tránh xung đột với @Published
        addEndMarker(coordinate: coordinate, title: title)
    }
    
    public func updateWaypoint(coordinate: CLLocationCoordinate2D, title: String, isStartPoint: Bool) {
        if isStartPoint {
            // Remove existing start point if any
            if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đi" }) {
                mapViewManager.mapView.removeAnnotations(annotations)
            }
            
            // Set the new start point
            self.startPoint = coordinate
            
            // Add an annotation for the start point
            let annotation = MLNPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            mapViewManager.mapView.addAnnotation(annotation)
            
            // Move camera to this point
            mapViewManager.moveCamera(to: coordinate, zoom: 14)
        } else {
            // Remove existing end point if any
            if let annotations = mapViewManager.mapView.annotations?.filter({ $0.title == "Điểm đến" }) {
                mapViewManager.mapView.removeAnnotations(annotations)
            }
            
            // Set the new end point
            self.endPoint = coordinate
            
            // Add an annotation for the end point
            let annotation = MLNPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = title
            mapViewManager.mapView.addAnnotation(annotation)
            
            // If we have both start and end, make sure to show both
            if startPoint != nil && endPoint != nil {
                // Could add logic to fit both points in view
            }
        }
    }
    
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping (Bool, String?) -> Void) {
        // Clear any existing route
        mapViewManager.removeAllPolylines()
        
        // Create waypoints for the start and end points
        let origin = Waypoint(coordinate: start)
        let destination = Waypoint(coordinate: end)
        
        // Set up the route options
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
        
        // For this demo, we'll just create a simple straight line route
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Create a simple route with just the start and end points
            let coordinatesArray: [[Double]] = [
                [start.longitude, start.latitude], 
                [end.longitude, end.latitude]
            ]
            
            // Create a sample route
            self.currentRoute = Route(
                json: ["coordinates": coordinatesArray],
                waypoints: [origin, destination],
                options: routeOptions
            )
            
            // Draw the route on the map
            self.mapViewManager.addPolyline(coordinates: [start, end])
            
            // Update navigation mode
            self.navigationMode = .route
            
            // Call the completion handler
            completion(true, "Route calculated successfully")
        }
        
        // In a real app, you would actually call the MapBox Directions API here
        // Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in ... }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> CLPlacemark? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first
        } catch {
            print("Reverse geocoding error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Enums
public enum MapMode {
    case singlePoint
    case wayPoint
    case cluster
    case animation
    case heatmap
    case compare
    case feature
    case navigation
}

public enum NavigationMode {
    case planning
    case active
    case complete
}

// MARK: - CLPlacemark Extension
extension CLPlacemark {
    func getFormattedAddress() -> String {
        var addressString = ""
        
        if let name = self.name {
            addressString += name
        }
        
        if let thoroughfare = self.thoroughfare {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += thoroughfare
        }
        
        if let subThoroughfare = self.subThoroughfare {
            if !addressString.isEmpty && !addressString.contains(subThoroughfare) {
                addressString += " " + subThoroughfare
            }
        }
        
        if let subLocality = self.subLocality {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += subLocality
        }
        
        if let locality = self.locality {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += locality
        }
        
        if let administrativeArea = self.administrativeArea {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += administrativeArea
        }
        
        if let postalCode = self.postalCode {
            if !addressString.isEmpty {
                addressString += " "
            }
            addressString += postalCode
        }
        
        if let country = self.country {
            if !addressString.isEmpty {
                addressString += ", "
            }
            addressString += country
        }
        
        return addressString
    }
} 