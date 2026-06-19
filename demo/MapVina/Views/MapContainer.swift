//
//  MapContainer.swift
//  MapVina
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import MapVina
import CoreLocation

struct MapContainer: UIViewRepresentable {
    @Binding var currentTab: Int
    var mapViewModel: MapViewModel
    var countrySettings: ContentViewCountrySettings
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> UIView {
        // Container view
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .white
        
        // Khởi tạo map view
        let mapView = mapViewModel.mapViewManager.mapView
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Thiết lập delegate
        mapView.delegate = context.coordinator
        
        // Thêm vào container
        containerView.addSubview(mapView)
        
        // Lưu tham chiếu vào coordinator
        context.coordinator.mapView = mapView
        context.coordinator.containerView = containerView
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Khi tab thay đổi, cập nhật cấu hình map mà không tạo lại nó
        if context.coordinator.currentTab != currentTab {
            context.coordinator.currentTab = currentTab
            updateMapForCurrentTab(context.coordinator)
        }
    }
    
    private func updateMapForCurrentTab(_ coordinator: Coordinator) {
        // Cập nhật chế độ bản đồ dựa trên tab hiện tại
        DispatchQueue.main.async {
            print("📱 Switching to tab: \(self.currentTab)")
            
            // We don't have currentTabIndex in MapViewModel, so comment out this line
            // self.mapViewModel.currentTabIndex = self.currentTab
            
            // Hiển thị loading
            self.isLoading = true
            
            // Xóa tất cả annotation hiện tại
            if let annotations = coordinator.mapView?.annotations, !annotations.isEmpty {
                print("🗑️ Removing \(annotations.count) existing annotations")
                coordinator.mapView?.removeAnnotations(annotations)
            } else {
                print("ℹ️ No annotations to remove")
            }
            
            // Cập nhật chế độ bản đồ
            switch self.currentTab {
            case 0:
                print("📍 Switching to Single Point mode")
                self.mapViewModel.updateMode(.singlePoint)
                coordinator.setupSinglePointMode()
            case 1:
                print("📍 Switching to Waypoint mode")
                self.mapViewModel.updateMode(.wayPoint)
                coordinator.setupWaypointMode()
            case 2:
                print("📍 Switching to Cluster mode")
                self.mapViewModel.updateMode(.cluster)
                coordinator.setupClusterMode()
            case 3:
                print("📍 Switching to Animation mode")
                self.mapViewModel.updateMode(.animation)
                coordinator.setupAnimationMode()
            case 4:
                print("📍 Switching to Feature mode")
                self.mapViewModel.updateMode(.feature)
                coordinator.setupFeatureMode()
            case 5:
                print("📍 Switching to Compare mode")
                self.mapViewModel.updateMode(.compare)
                coordinator.setupCompareMode()
            default:
                print("⚠️ Unknown tab index: \(self.currentTab)")
                break
            }
            
            // Ẩn loading sau khi hoàn thành
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
                print("✅ Tab switch completed")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapContainer
        var mapView: MLNMapView?
        var containerView: UIView?
        var currentTab: Int = 0
        var tapGesture: UITapGestureRecognizer?
        
        init(_ parent: MapContainer) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - MLNMapViewDelegate
        
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            print("✅ Map style loaded successfully")
            
            // Mark map as loaded and restore any saved state
            parent.mapViewModel.isStyleLoaded = true
            parent.mapViewModel.restoreMapState()
            
            // Listen for single point mode setup requests
            NotificationCenter.default.addObserver(forName: Notification.Name("RequestSinglePointModeSetup"), object: nil, queue: .main) { [weak self] _ in
                guard let self = self else { return }
                print("📣 Received notification for setting up single point mode")
                if self.parent.currentTab == 0 {
                    self.setupSinglePointMode()
                }
            }
            
            // Listen for waypoint mode setup requests
            NotificationCenter.default.addObserver(forName: Notification.Name("RequestWaypointModeSetup"), object: nil, queue: .main) { [weak self] _ in
                guard let self = self else { return }
                print("📣 Received notification for setting up waypoint mode")
                if self.parent.currentTab == 1 {
                    self.setupWaypointMode()
                }
            }
            
            // Set up initial mode for current tab
            print("🏁 Setting up initial mode for tab \(parent.currentTab)")
            setupInitialMode()
        }
        
        // MARK: - Tab Mode Setup
        
        func setupInitialMode() {
            // Thiết lập chế độ ban đầu dựa vào tab hiện tại
            switch currentTab {
            case 0:
                setupSinglePointMode()
            case 1:
                setupWaypointMode()
            case 2:
                setupClusterMode()
            case 3:
                setupAnimationMode()
            case 4:
                setupFeatureMode()
            case 5:
                setupCompareMode()
            default:
                break
            }
        }
        
        func setupSinglePointMode() {
            guard let mapView = mapView else { return }
            
            print("🔄 Setting up Single Point Mode")
            
            // Xóa và thiết lập lại gesture tap cho single point
            if let oldGesture = tapGesture {
                print("🗑️ Removing old gesture recognizer")
                mapView.removeGestureRecognizer(oldGesture)
            }
            
            print("➕ Adding new tap gesture recognizer")
            let newTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSinglePointTap(_:)))
            // Đảm bảo gesture không xung đột với các gesture khác của map
            newTapGesture.numberOfTapsRequired = 1
            newTapGesture.numberOfTouchesRequired = 1
            newTapGesture.delaysTouchesBegan = false
            newTapGesture.delaysTouchesEnded = false
            newTapGesture.cancelsTouchesInView = false
            mapView.addGestureRecognizer(newTapGesture)
            self.tapGesture = newTapGesture
            
            // Thiết lập zoom và center
            let defaultCoordinate = parent.countrySettings.location
            parent.mapViewModel.mapViewManager.moveCamera(to: defaultCoordinate, zoom: 12)
            print("🌎 Centered map at \(defaultCoordinate.latitude), \(defaultCoordinate.longitude)")
            
            // Đảm bảo parent.mapViewModel.isMapReady là true
            DispatchQueue.main.async {
                if !self.parent.mapViewModel.isMapReady {
                    print("⚠️ isMapReady was false, setting to true")
                    self.parent.mapViewModel.isMapReady = true
                }
                
                if !self.parent.mapViewModel.isStyleLoaded {
                    print("⚠️ isStyleLoaded was false, setting to true")
                    self.parent.mapViewModel.isStyleLoaded = true
                }
            }
            
            // Cấu hình onMapTapped callback
            parent.mapViewModel.onMapTapped = { [weak self] coordinate in
                guard let self = self else { return }
                print("🎯 Map tapped at coordinates via callback: \(coordinate.latitude), \(coordinate.longitude)")
                
                // Đánh dấu loading đang diễn ra
                DispatchQueue.main.async {
                    self.parent.isLoading = true
                }
                
                // Thêm marker
                self.parent.mapViewModel.addMarker(at: coordinate, title: "Vị trí đã chọn")
                
                // Ẩn loading
                DispatchQueue.main.async {
                    self.parent.isLoading = false
                }
            }
        }
        
        func setupWaypointMode() {
            guard let mapView = mapView else { 
                print("❌ setupWaypointMode: mapView is nil!")
                return 
            }
            
            print("🔄 Setting up Waypoint Mode")
            
            // Xóa và thiết lập lại gesture tap cho waypoint
            if let oldGesture = tapGesture {
                print("🗑️ Removing old gesture recognizer")
                mapView.removeGestureRecognizer(oldGesture)
            }
            
            print("➕ Adding new tap gesture recognizer for waypoint mode")
            let newTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleWaypointTap(_:)))
            // Đảm bảo gesture không xung đột với các gesture khác của map
            newTapGesture.numberOfTapsRequired = 1
            newTapGesture.numberOfTouchesRequired = 1
            newTapGesture.delaysTouchesBegan = false
            newTapGesture.delaysTouchesEnded = false
            newTapGesture.cancelsTouchesInView = false
            mapView.addGestureRecognizer(newTapGesture)
            self.tapGesture = newTapGesture
            
            // Thiết lập zoom và center
            let defaultCoordinate = parent.countrySettings.location
            parent.mapViewModel.mapViewManager.moveCamera(to: defaultCoordinate, zoom: 12)
            print("🌎 Centered map at \(defaultCoordinate.latitude), \(defaultCoordinate.longitude)")
            
            // Đảm bảo parent.mapViewModel.isMapReady là true
            DispatchQueue.main.async {
                if !self.parent.mapViewModel.isMapReady {
                    print("⚠️ isMapReady was false, setting to true")
                    self.parent.mapViewModel.isMapReady = true
                }
                
                if !self.parent.mapViewModel.isStyleLoaded {
                    print("⚠️ isStyleLoaded was false, setting to true")
                    self.parent.mapViewModel.isStyleLoaded = true
                }
            }
            
            print("✅ Waypoint mode setup completed")
        }
        
        func setupClusterMode() {
            guard let mapView = mapView else { 
                print("❌ setupClusterMode: mapView is nil!")
                return 
            }
            
            print("🔄 Setting up Cluster Mode in MapContainer")
            
            // Xóa gesture cũ
            if let oldGesture = tapGesture {
                print("🗑️ Removing old gesture recognizer")
                mapView.removeGestureRecognizer(oldGesture)
                self.tapGesture = nil
            }
            
            // Clear any existing annotations
            if let annotations = mapView.annotations {
                print("🗑️ Removing \(annotations.count) existing annotations")
                mapView.removeAnnotations(annotations)
            }
            
            // We don't need to create a new ClusterView here, as MapClusterView will handle that
            
            // Set up cluster mode in the view model
            print("⚙️ Calling setupClusterPoints on the view model")
            parent.mapViewModel.setupClusterPoints()
            
            // Make sure style is loaded
            if mapView.style == nil {
                print("⚠️ Map style is nil - waiting for style to load")
            }
            
            print("✅ Cluster mode setup completed in MapContainer")
        }
        
        func setupAnimationMode() {
            guard let mapView = mapView else { return }
            
            // Xóa gesture cũ
            if let oldGesture = tapGesture {
                mapView.removeGestureRecognizer(oldGesture)
                self.tapGesture = nil
            }
            
            // Thiết lập tuyến đường và animation
            parent.mapViewModel.clearMap()
            
            // Thiết lập zoom và center
            let defaultCoordinate = parent.countrySettings.location
            parent.mapViewModel.mapViewManager.moveCamera(to: defaultCoordinate, zoom: 12)
        }
        
        func setupFeatureMode() {
            guard let mapView = mapView else { return }
            
            // Xóa gesture cũ
            if let oldGesture = tapGesture {
                mapView.removeGestureRecognizer(oldGesture)
                self.tapGesture = nil
            }
            
            // Thiết lập zoom và center
            let defaultCoordinate = parent.countrySettings.location
            parent.mapViewModel.mapViewManager.moveCamera(to: defaultCoordinate, zoom: 12)
        }
        
        func setupCompareMode() {
            guard let mapView = mapView else { return }
            
            // Xóa gesture cũ
            if let oldGesture = tapGesture {
                mapView.removeGestureRecognizer(oldGesture)
                self.tapGesture = nil
            }
            
            // Thiết lập zoom và center
            let defaultCoordinate = parent.countrySettings.location
            parent.mapViewModel.mapViewManager.moveCamera(to: defaultCoordinate, zoom: 12)
            
            // Direct implementation instead of using showCompareView
            print("Setting up compare mode")
            // parent.mapViewModel.showCompareView = true
        }
        
        // MARK: - Gesture Handlers
        
        @objc func handleSinglePointTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }
            
            // Kiểm tra xem đã có đang xử lý gesture khác không
            if parent.isLoading { return }
            
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            print("🔍 Tap detected at coordinates: \(coordinate.latitude), \(coordinate.longitude)")
            
            // Gọi callback onMapTapped để xử lý tap theo cách đã thiết lập trong MapSinglePointView
            if let onMapTapped = parent.mapViewModel.onMapTapped {
                print("🔄 Calling onMapTapped callback")
                onMapTapped(coordinate)
                return
            }
            
            // Nếu chưa có callback được thiết lập, xử lý theo cách cũ
            print("⚠️ No onMapTapped callback found, using direct implementation")
            
            // Thiết lập trạng thái loading
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
            
            // Quay lại main thread để cập nhật UI
            DispatchQueue.main.async {
                print("🌍 Adding marker directly to MapView")
                
                // Xóa tất cả các đánh dấu hiện có
                if let annotations = self.mapView?.annotations {
                    print("🗑️ Removing \(annotations.count) existing annotations")
                    self.mapView?.removeAnnotations(annotations)
                } else {
                    print("⚠️ No annotations to remove")
                }
                
                // Thêm marker trực tiếp vào mapView
                let annotation = MLNPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Vị trí được chọn"
                self.mapView?.addAnnotation(annotation)
                print("✅ Added marker at \(coordinate.latitude), \(coordinate.longitude)")
                
                // Zoom đến vị trí được chọn
                self.mapView?.setCenter(coordinate, zoomLevel: 15, animated: true)
                print("🔍 Zoomed to coordinate")
                
                // Hiển thị toast thông báo 
                self.showToastDirectly(message: "Đã chọn vị trí")
                
                // Ẩn loading
                self.parent.isLoading = false
            }
        }
        
        // Phương thức trực tiếp hiển thị toast không qua ContentView
        private func showToastDirectly(message: String) {
            guard let mapView = self.mapView else { return }
            
            print("🍞 Showing toast directly on map: \(message)")
            
            // Tạo toast view
            let toastView = UIView()
            toastView.tag = 9999
            toastView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            toastView.layer.cornerRadius = 10
            toastView.clipsToBounds = true
            
            // Tạo label
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 14)
            label.numberOfLines = 0
            label.textAlignment = .center
            
            // Thêm label vào toast
            toastView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8),
                label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16)
            ])
            
            // Xóa toast cũ nếu có
            if let oldToast = mapView.viewWithTag(9999) {
                oldToast.removeFromSuperview()
            }
            
            // Thêm toast vào map
            mapView.addSubview(toastView)
            toastView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toastView.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -32),
                toastView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
                toastView.widthAnchor.constraint(lessThanOrEqualTo: mapView.widthAnchor, constant: -32),
            ])
            
            // Animation hiển thị toast
            toastView.alpha = 0
            UIView.animate(withDuration: 0.3, animations: {
                toastView.alpha = 1
                
                // Tự động ẩn toast sau 3 giây
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    UIView.animate(withDuration: 0.3, animations: {
                        toastView.alpha = 0
                    }) { _ in
                        toastView.removeFromSuperview()
                    }
                }
            })
            
            // Bên cạnh đó, vẫn thử gọi phương thức toast qua ContentView
            self.findAndShowToast(message: message)
        }
        
        // Phương thức mới để tìm và hiển thị toast
        private func findAndShowToast(message: String) {
            // Tìm cửa sổ hiện tại
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let window = windowScene.windows.first else {
                    return
                }
                
                // Tìm rootViewController
                var currentController = window.rootViewController
                
                // Tìm ContentView thông qua UIHostingController
                while currentController != nil {
                    if let hostingController = currentController as? UIHostingController<ContentView> {
                        // Sử dụng viewModel.showToast thay vì truy cập trực tiếp
                        hostingController.rootView.viewModel.showToast(message)
                        break
                    } else if let navigationController = currentController as? UINavigationController {
                        currentController = navigationController.visibleViewController
                    } else if let tabController = currentController as? UITabBarController {
                        currentController = tabController.selectedViewController
                    } else if let presentedController = currentController?.presentedViewController {
                        currentController = presentedController
                    } else {
                        break
                    }
                }
            }
        }
        
        @objc func handleWaypointTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView, parent.mapViewModel.mode == .wayPoint else { return }
            
            // Lấy vị trí chạm và chuyển thành tọa độ
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            print("📍 handleWaypointTap: Tap detected at \(coordinate.latitude), \(coordinate.longitude)")
            
            // Ưu tiên sử dụng callback từ MapWayPointView nếu có
            if let onMapTapped = parent.mapViewModel.onMapTapped {
                print("🔄 Calling onMapTapped callback from MapWayPointView")
                onMapTapped(coordinate)
                return
            }
            
            // Nếu không có callback, sử dụng phương thức xử lý cũ
            print("⚠️ No onMapTapped callback found, using direct implementation")
            parent.mapViewModel.addWaypoint(at: coordinate)
        }
        
        // UIGestureRecognizerDelegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Cho phép xử lý cùng lúc với các gesture khác (như pinch để zoom)
            return true
        }
        
        deinit {
            print("♻️ MapContainer.Coordinator deinit")
            // Loại bỏ observer để tránh memory leak
            NotificationCenter.default.removeObserver(self)
            
            // Loại bỏ gesture recognizer
            if let gesture = tapGesture, let mapView = mapView {
                mapView.removeGestureRecognizer(gesture)
                tapGesture = nil
            }
        }
    }
} 