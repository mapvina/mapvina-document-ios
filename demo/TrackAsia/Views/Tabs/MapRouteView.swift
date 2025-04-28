import SwiftUI
import CoreLocation
import TrackAsia

struct MapRouteView: View {
    // Sử dụng ObservedObject thay vì StateObject
    @ObservedObject var mapViewModel: MapViewModel
    @State private var startAddress: String = ""
    @State private var endAddress: String = ""
    @State private var isSettingStart: Bool = true
    @State private var routeCalculated: Bool = false
    
    var body: some View {
        VStack {
            // Thanh tìm kiếm cho điểm bắt đầu
            HStack {
                Text("Điểm đi:")
                    .font(.headline)
                    .frame(width: 70, alignment: .leading)
                
                TextField("Tìm điểm bắt đầu", text: $startAddress)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSettingStart ? Color.blue : Color.gray, lineWidth: 1)
                    )
                    .onTapGesture {
                        isSettingStart = true
                    }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Thanh tìm kiếm cho điểm kết thúc
            HStack {
                Text("Điểm đến:")
                    .font(.headline)
                    .frame(width: 70, alignment: .leading)
                
                TextField("Tìm điểm kết thúc", text: $endAddress)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(!isSettingStart ? Color.blue : Color.gray, lineWidth: 1)
                    )
                    .onTapGesture {
                        isSettingStart = false
                    }
            }
            .padding(.horizontal)
            .padding(.bottom, 5)
            
            // Nút tính toán tuyến đường
            if !startAddress.isEmpty && !endAddress.isEmpty {
                Button(action: {
                    // Tính toán tuyến đường ở đây
                    print("Calculating route from \(startAddress) to \(endAddress)")
                    calculateRoute()
                }) {
                    Text("Tính toán tuyến đường")
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom, 10)
            }
            
            // Hiển thị bản đồ
            ZStack {
                // Màn hình bản đồ chính
                Color.clear // Bản đồ đã được nhúng trong ContentView
                
                // Các nút điều khiển bản đồ
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 10) {
                            // Nút định vị
                            Button(action: {
                                mapViewModel.centerOnUserLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .padding(12)
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 16)
                        }
                        .padding(.bottom, 100) // Để không che phần hướng dẫn
                    }
                    
                    if routeCalculated {
                        VStack(spacing: 4) {
                            Text("Thời gian: 25 phút")
                                .font(.headline)
                            Text("Khoảng cách: 5.2 km")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.bottom, 20)
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .onAppear {
            setupMapForRouting()
        }
    }
    
    private func setupMapForRouting() {
        // Thiết lập map để sẵn sàng cho tính năng routing
        print("Setting up map for routing")
        
        // Đặt lại mode của map
        mapViewModel.navigationMode = .route
        
        // Thiết lập callback để xử lý tap trên bản đồ
        mapViewModel.onMapTapped = { coordinate in
            handleMapTap(at: coordinate)
        }
    }
    
    private func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        print("Map tapped in route mode at: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Reverse geocode to get address
        Task {
            if let placemark = await mapViewModel.reverseGeocode(coordinate: coordinate) {
                let address = placemark.getFormattedAddress()
                
                DispatchQueue.main.async {
                    if isSettingStart {
                        startAddress = address
                        mapViewModel.setStartPoint(coordinate: coordinate, title: "Điểm đi")
                    } else {
                        endAddress = address
                        mapViewModel.setEndPoint(coordinate: coordinate, title: "Điểm đến")
                    }
                    
                    // Nếu cả hai điểm đã được đặt, tự động tính toán tuyến đường
                    if !startAddress.isEmpty && !endAddress.isEmpty {
                        calculateRoute()
                    }
                }
            }
        }
    }
    
    private func calculateRoute() {
        guard let startPoint = mapViewModel.startPoint,
              let endPoint = mapViewModel.endPoint else {
            print("Cannot calculate route: missing start or end point")
            return
        }
        
        // Gọi hàm tính toán tuyến đường
        mapViewModel.calculateRoute(from: startPoint, to: endPoint) { success, message in
            DispatchQueue.main.async {
                if success {
                    self.routeCalculated = true
                    print("Route calculated successfully")
                } else {
                    print("Failed to calculate route: \(message ?? "Unknown error")")
                }
            }
        }
    }
} 