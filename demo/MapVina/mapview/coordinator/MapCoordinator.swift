// MapCoordinator.swift - Tách từ ContentView

import SwiftUI
import MapVina
import CoreLocation

// MARK: - MapCoordinator
class MapCoordinator: NSObject, MLNMapViewDelegate, UIGestureRecognizerDelegate {
    var viewModel: MapViewModel
    var geocodingRepository = GeocodingRepository()
    var currentToastMessage: String?
    var toastCoordinate: CLLocationCoordinate2D?
    var tapGesture: UITapGestureRecognizer?
    var isGestureEnabled = false // Biến để kiểm soát xem gesture có được kích hoạt không
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init()
        // Chúng ta sẽ không thiết lập gesture recognizer ở đây nữa
        // vì nó sẽ được xử lý trực tiếp trong MapTabViewController
        setupObservers()
    }
    
    // Hàm này được giữ lại để tương thích nhưng không thực sự thêm gesture mới
    private func setupTapGesture() {
        // Không thêm gesture vào map view ở đây để tránh xung đột
        print("MapCoordinator's gesture setup is disabled to avoid conflicts")
    }
    
    // UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // Cho phép nhiều gesture cùng lúc
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Luôn trả về false vì chúng ta sẽ xử lý gesture trong MapTabViewController
        return false
    }
    
    private func setupObservers() {
        // Đăng ký để nhận thông báo khi có kết quả geocoding
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAddressUpdate),
            name: NSNotification.Name("AddressUpdated"),
            object: nil
        )
    }
    
    @objc func handleAddressUpdate(_ notification: Notification) {
        // Chỉ xử lý thông báo nếu có địa chỉ và tọa độ
        if let addresses = notification.userInfo?["addresses"] as? [AddressModel], 
           let coordinate = notification.userInfo?["coordinate"] as? CLLocationCoordinate2D,
           !addresses.isEmpty {
            
            // Lấy địa chỉ và hiển thị 
            let address = addresses[0]
            print("📍 Đã nhận địa chỉ trong MapCoordinator: \(address.label)")
            
            // Xóa toast cũ nếu có
            if let controller = UIApplication.shared.windows.first?.rootViewController {
                if let oldToast = controller.view.viewWithTag(9999) {
                    oldToast.removeFromSuperview()
                }
            }
            
            // Hiển thị thông báo toast với địa chỉ
            self.showToast(message: address.label, at: coordinate)
        }
    }
    
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        // Chỉ xử lý sự kiện tap khi ở chế độ SinglePoint
        guard viewModel.mode == .singlePoint else {
            print("Tap ignored - not in SinglePoint mode")
            return
        }
        
        print("Map tapped in SinglePoint mode")
        let point = gesture.location(in: viewModel.mapViewManager.mapView)
        let coordinate = viewModel.mapViewManager.mapView.convert(point, toCoordinateFrom: viewModel.mapViewManager.mapView)
        print("Tap at coordinate: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Đặt marker tại vị trí đã chọn
        viewModel.addMarker(at: coordinate, title: "Vị trí đã chọn")
        print("Marker added at tap location")
        
        // Tìm địa chỉ từ tọa độ
        geocodingRepository.fetchGeocoding(
            lat: String(format: "%.6f", coordinate.latitude),
            lng: String(format: "%.6f", coordinate.longitude)
        )
        print("Geocoding request sent")
        
        // Hiển thị thông báo tạm thời trong khi chờ kết quả geocoding
        showToast(message: "Đang tìm địa chỉ...", at: coordinate)
        print("Temporary toast displayed")
    }
    
    // Hiển thị toast với thông báo và tọa độ
    private func showToast(message: String, at coordinates: CLLocationCoordinate2D) {
        let mapview = viewModel.mapViewManager.mapView
        guard !message.isEmpty else { return }
        
        let toastView = UIView()
        toastView.tag = 999
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true
        
        let label = UILabel()
        label.text = "\(message)\nLat: \(String(format: "%.6f", coordinates.latitude)), Long: \(String(format: "%.6f", coordinates.longitude))"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        toastView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -16)
        ])
        
        mapview.addSubview(toastView)
        toastView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toastView.bottomAnchor.constraint(equalTo: mapview.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            toastView.centerXAnchor.constraint(equalTo: mapview.centerXAnchor),
            toastView.widthAnchor.constraint(lessThanOrEqualTo: mapview.widthAnchor, constant: -32),
        ])
        
        // Animation
        toastView.alpha = 0
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }) { _ in
            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                UIView.animate(withDuration: 0.3, animations: {
                    toastView.alpha = 0
                }) { _ in
                    toastView.removeFromSuperview()
                }
            }
        }
    }
    
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        viewModel.isStyleLoaded = true
        viewModel.restoreMapState()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 