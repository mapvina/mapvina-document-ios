//
//  MapWayPointView.swift
//  MapVina
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import MapVina
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation

// MARK: - SimpleRouteInfo

class SimpleRouteInfo {
    let distance: Double
    let expectedTravelTime: Double
    let startPoint: CLLocationCoordinate2D
    let endPoint: CLLocationCoordinate2D
    
    init(distance: Double, expectedTravelTime: Double, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.startPoint = startPoint
        self.endPoint = endPoint
    }
}

// MARK: - MapWayPointView

struct MapWayPointView: View {
    // MARK: - Properties
    
    let viewModel: MapViewModel
    
    @State private var showNavigation = false
    @State private var canStartNavigation = false
    @State private var isCalculatingRoute = false
    @State private var routeErrorMessage: String?
    
    @State private var waypoints: [CLLocationCoordinate2D] = []
    @State private var currentRoute: Route?
    @State private var simpleRouteInfo: SimpleRouteInfo?
    
    // MARK: - Initialization
    
    init(mapViewModel: MapViewModel) {
        self.viewModel = mapViewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
            
                waypointsPanel
            }
            if let errorMessage = routeErrorMessage {
                errorMessageView(message: errorMessage)
            }
            if isCalculatingRoute {
                loadingIndicator
            }
            if showNavigation {
                NavigationUIView(
                    route: currentRoute,
                    simpleRouteInfo: simpleRouteInfo,
                    waypoints: waypoints,
                    showNavigation: $showNavigation
                )
                .edgesIgnoringSafeArea(Edge.Set.all)
            }
        }
        .onAppear {
            print("🔄 MapWayPointView.onAppear called")
            setupView()
        }
        .onDisappear {
            self.viewModel.onMapTapped = nil
        }
    }
    
    @ViewBuilder
    private var waypointsPanel: some View {
        if !waypoints.isEmpty {
            VStack(spacing: 8) {
                waypointInfoView
                
                if waypoints.count > 1 {
                    calculateRouteButton
                }
                
                if currentRoute != nil {
                    startNavigationButton
                    routeInfoView
                }
                
                resetButton
            }
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        } else {
            instructionsView
        }
    }
    
    @ViewBuilder
    private var waypointInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Điểm đi: \(waypoints.first != nil ? "Đã chọn" : "Chưa chọn")")
                .font(.subheadline)
                .foregroundColor(.black)
            
            Text("Điểm đến: \(waypoints.count > 1 ? "Đã chọn" : "Chưa chọn")")
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var calculateRouteButton: some View {
        Button(action: calculateRoute) {
            Text("Tìm đường đi")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color("colorBlue"))
                .cornerRadius(8)
        }
        .disabled(isCalculatingRoute)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var startNavigationButton: some View {
        Button(action: startNavigation) {
            Text("Bắt đầu điều hướng")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var routeInfoView: some View {
        if let route = currentRoute {
            Text("Khoảng cách: \(String(format: "%.2f", route.distance / 1000)) km")
                .font(.subheadline)
                .foregroundColor(.black)
            Text("Thời gian: \(formatTime(seconds: route.expectedTravelTime))")
                .font(.subheadline)
                .foregroundColor(.black)
        }
    }
    
    @ViewBuilder
    private var resetButton: some View {
        Button(action: resetWaypoints) {
            Text("Đặt lại")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var instructionsView: some View {
        VStack(spacing: 16) {
            Text("Hướng dẫn")
                .font(.headline)
                .foregroundColor(.black)
            
            Text("Chạm vào bản đồ để chọn điểm đi, sau đó chạm lần nữa để chọn điểm đến.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private func errorMessageView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 200)
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        VStack {
            Spacer()
            ProgressView("Đang tính toán tuyến đường...")
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.bottom, 200)
        }
    }
    
    private func setupView() {
        syncFromViewModel()
        self.viewModel.updateMode(.wayPoint)
        print("🔄 Setting onMapTapped handler in MapWayPointView")
        self.viewModel.onMapTapped = { coordinate in
            print("🎯 onMapTapped callback triggered in MapWayPointView")
            self.handleMapTap(at: coordinate)
        }
        print("✅ MapWayPointView.onAppear completed")
    }
    
    private func syncFromViewModel() {
        self.waypoints = viewModel.waypoints
        self.currentRoute = viewModel.currentRoute
    }
    
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        print("🚩 MapWayPointView.handleMapTap called at \(coordinate.latitude), \(coordinate.longitude)")
        if currentRoute != nil {
            clearExistingRoute()
        }
        
        if waypoints.isEmpty {
            print("📌 Adding starting point")
            addStartingPoint(at: coordinate)
        } else if waypoints.count == 1 {
            print("📌 Adding destination point")
            addDestinationPoint(at: coordinate)
        } else {
            print("📌 Replacing destination with new point")
            replaceDestination(with: coordinate)
        }
        syncFromViewModel()
    }
    
    private func clearExistingRoute() {
        DispatchQueue.main.async {
            self.viewModel.currentRoute = nil
            self.viewModel.mapViewManager.removeAllPolylines()
            self.currentRoute = nil
        }
    }
    
    private func addStartingPoint(at coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.removeAnnotations(withTitle: "Điểm đi")
            self.addAnnotation(at: coordinate, title: "Điểm đi")
            self.viewModel.mapViewManager.moveCamera(to: coordinate, zoom: 14)
            self.viewModel.waypoints.append(coordinate)
            self.waypoints = self.viewModel.waypoints
        }
    }
    
    private func addDestinationPoint(at coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.removeAnnotations(withTitle: "Điểm đến")
            self.addAnnotation(at: coordinate, title: "Điểm đến")
            self.viewModel.waypoints.append(coordinate)
            self.waypoints = self.viewModel.waypoints
        }
    }
    
    private func replaceDestination(with coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.viewModel.waypoints.removeLast()
            self.removeAnnotations(withTitle: "Điểm đến")
            self.addAnnotation(at: coordinate, title: "Điểm đến")
            self.viewModel.waypoints.append(coordinate)
            self.waypoints = self.viewModel.waypoints
            self.clearExistingRoute()
        }
    }
    
    private func removeAnnotations(withTitle title: String) {
        if let annotations = self.viewModel.mapViewManager.mapView.annotations?.filter({ $0.title == title }) {
            self.viewModel.mapViewManager.mapView.removeAnnotations(annotations)
        }
    }
    
    private func addAnnotation(at coordinate: CLLocationCoordinate2D, title: String) {
        let annotation = MLNPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title
        self.viewModel.mapViewManager.mapView.addAnnotation(annotation)
    }
    
    // MARK: - Route Calculation
    
    private func calculateRoute() {
        guard waypoints.count >= 2 else {
            showError("Cần chọn ít nhất hai điểm để tính toán tuyến đường")
            return
        }
        
        isCalculatingRoute = true
        let startPoint = waypoints[0]
        let endPoint = waypoints[1]
        let origin = Waypoint(coordinate: startPoint)
        let destination = Waypoint(coordinate: endPoint)
        let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
        print("🔄 Đang tính toán tuyến đường...")
        Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleRouteCalculationError(error, startPoint: startPoint, endPoint: endPoint)
                    return
                }
                
                if let firstRoute = routes?.first {
                    self.handleSuccessfulRouteCalculation(firstRoute, startPoint: startPoint, endPoint: endPoint)
                } else {
                    print("⚠️ Không nhận được tuyến đường từ API, sử dụng đường thẳng thay thế")
                    self.drawStraightLine(from: startPoint, to: endPoint)
                }
                self.isCalculatingRoute = false
            }
        }
    }
    
    private func handleRouteCalculationError(_ error: Error, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        print("❌ Lỗi khi tính toán tuyến đường: \(error.localizedDescription)")
        showError("Không thể tính toán tuyến đường: \(error.localizedDescription)")
        self.drawStraightLine(from: startPoint, to: endPoint)
    }
    
    private func handleSuccessfulRouteCalculation(_ route: Route, startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        self.viewModel.currentRoute = route
        self.currentRoute = route
        if let coordinates = route.coordinates {
            self.viewModel.mapViewManager.addPolyline(coordinates: coordinates)
        } else {
            self.viewModel.mapViewManager.addPolyline(coordinates: [startPoint, endPoint])
        }
        print("✅ Đã tính toán tuyến đường: \(String(format: "%.2f", route.distance / 1000)) km")
        self.simpleRouteInfo = SimpleRouteInfo(
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            startPoint: startPoint,
            endPoint: endPoint
        )
        self.canStartNavigation = true
    }
    
    private func showError(_ message: String) {
        self.routeErrorMessage = message
        self.isCalculatingRoute = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.routeErrorMessage = nil
        }
    }
    
    private func drawStraightLine(from startPoint: CLLocationCoordinate2D, to endPoint: CLLocationCoordinate2D) {
        let distanceInMeters = self.calculateDistance(from: startPoint, to: endPoint)
        let estimatedTime = distanceInMeters / 13.8 // ~50 km/h tốc độ trung bình
        self.viewModel.mapViewManager.addPolyline(coordinates: [startPoint, endPoint])
        let simpleRoute = SimpleRouteInfo(
            distance: distanceInMeters,
            expectedTravelTime: estimatedTime,
            startPoint: startPoint,
            endPoint: endPoint
        )
        self.simpleRouteInfo = simpleRoute
        self.canStartNavigation = true
        
        print("✅ Đã tính toán đường thẳng: \(String(format: "%.2f", distanceInMeters / 1000)) km")
    }
    
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371000.0 // Bán kính trái đất tính bằng mét
        
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLat = (end.latitude - start.latitude) * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    private func startNavigation() {
        print("🚗 Starting navigation")
        
        if currentRoute != nil || simpleRouteInfo != nil {
            showNavigation = true
            print("🚗 Starting navigation with \(currentRoute != nil ? "Route object" : "SimpleRouteInfo")")
        } else {
            print("⚠️ Cannot start navigation: No route available")
        }
    }
    
    private func resetWaypoints() {
        DispatchQueue.main.async {
            if let annotations = self.viewModel.mapViewManager.mapView.annotations?.filter({ annotation in
                if let title = annotation.title {
                    return ((title?.contains("Waypoint")) != nil) || ((title?.contains("Điểm")) != nil)
                }
                return false
            }) {
                self.viewModel.mapViewManager.mapView.removeAnnotations(annotations)
            }
            self.viewModel.mapViewManager.removeAllPolylines()
            self.viewModel.waypoints.removeAll()
            self.waypoints.removeAll()
            self.viewModel.currentRoute = nil
            self.currentRoute = nil
            self.simpleRouteInfo = nil
            self.canStartNavigation = false
            self.routeErrorMessage = nil
            print("✅ Reset waypoints: Đã xóa tất cả điểm đánh dấu và tuyến đường")
        }
    }
    
    private func formatTime(seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - NavigationUIView

struct NavigationUIView: UIViewControllerRepresentable {
    let route: Route?
    let simpleRouteInfo: SimpleRouteInfo?
    let waypoints: [CLLocationCoordinate2D]
    @Binding var showNavigation: Bool
    
    init(route: Route? = nil, simpleRouteInfo: SimpleRouteInfo? = nil, waypoints: [CLLocationCoordinate2D], showNavigation: Binding<Bool>) {
        self.route = route
        self.simpleRouteInfo = simpleRouteInfo
        self.waypoints = waypoints
        self._showNavigation = showNavigation
    }
    
    func makeUIViewController(context: Context) -> NavigationViewController {
        let navigationVC = NavigationViewController(dayStyle: DayStyle(demoStyle: ()), nightStyle: NightStyle(demoStyle: ()))
        navigationVC.mapView.tracksUserCourse = false
        navigationVC.mapView.showsUserLocation = true
        if let firstWaypoint = waypoints.first {
            navigationVC.mapView.centerCoordinate = firstWaypoint
        }
        navigationVC.delegate = context.coordinator
        setupNavigationRoute(for: navigationVC)
        return navigationVC
    }
    
    private func setupNavigationRoute(for navigationVC: NavigationViewController) {
        if let routeObject = route {
            startNavigation(with: routeObject, using: navigationVC)
        } else if let simpleInfo = simpleRouteInfo {
            createAndStartSimpleNavigation(with: simpleInfo, using: navigationVC)
        }
    }
    
    private func startNavigation(with route: Route?, using navigationVC: NavigationViewController) {
        guard let route = route else { return }
        
        let simulatedLocationManager = SimulatedLocationManager(route: route)
        simulatedLocationManager.speedMultiplier = 2.0
        navigationVC.startNavigation(with: route, animated: true, locationManager: simulatedLocationManager)
    }
    
    private func createAndStartSimpleNavigation(with simpleInfo: SimpleRouteInfo, using navigationVC: NavigationViewController) {
        let origin = Waypoint(coordinate: simpleInfo.startPoint)
        let destination = Waypoint(coordinate: simpleInfo.endPoint)
        let options = NavigationRouteOptions(waypoints: [origin, destination])
        let jsonData: [String: Any] = [
            "duration": simpleInfo.expectedTravelTime,
            "distance": simpleInfo.distance,
            "coordinates": [
                [simpleInfo.startPoint.longitude, simpleInfo.startPoint.latitude],
                [simpleInfo.endPoint.longitude, simpleInfo.endPoint.latitude]
            ]
        ]
        let fakeRoute: Route? = Route(json: jsonData as [String: AnyObject], waypoints: [origin, destination], options: options)
        
        if fakeRoute != nil {
            startNavigation(with: fakeRoute, using: navigationVC)
        } else {
            print("⚠️ Không thể tạo route từ SimpleRouteInfo")
            let routeLineCoordinates = [simpleInfo.startPoint, simpleInfo.endPoint]
            let polyline = MLNPolyline(coordinates: routeLineCoordinates, count: UInt(routeLineCoordinates.count))
            navigationVC.mapView.addAnnotation(polyline)
            addMarkers(for: simpleInfo, to: navigationVC)
        }
    }
    
    private func addMarkers(for simpleInfo: SimpleRouteInfo, to navigationVC: NavigationViewController) {
        let originAnnotation = MLNPointAnnotation()
        originAnnotation.coordinate = simpleInfo.startPoint
        originAnnotation.title = "Điểm đi"
        
        let destinationAnnotation = MLNPointAnnotation()
        destinationAnnotation.coordinate = simpleInfo.endPoint
        destinationAnnotation.title = "Điểm đến"
        
        navigationVC.mapView.addAnnotations([originAnnotation, destinationAnnotation])
    }
    
    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {
   
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NavigationViewControllerDelegate {
        var parent: NavigationUIView
        
        init(_ parent: NavigationUIView) {
            self.parent = parent
        }
        
        func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
            parent.showNavigation = false
        }
        
        func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
            return true
        }
        
        func navigationViewControllerDidFinishRouting(_ navigationViewController: NavigationViewController) {
            navigationViewController.endNavigation()
            DispatchQueue.main.async {
                self.parent.showNavigation = false
            }
        }
    }
}

#Preview {
    MapWayPointView(mapViewModel: MapViewModel())
} 
