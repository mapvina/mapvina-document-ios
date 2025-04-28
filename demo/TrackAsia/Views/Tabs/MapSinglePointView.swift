//
//  MapSinglePointView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia
import UIKit

// Create a simplified search field component instead of using AddressSearchView
struct SearchField: View {
    @Binding var searchText: String
    var viewModel: MapViewModel
    
    var body: some View {
        TextField("Nhập địa chỉ hoặc tên địa điểm", text: $searchText)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
}

struct MapSinglePointView: View {
    // Quan trọng: Sử dụng ObservedObject thay vì StateObject vì nó sẽ được truyền từ ContentView
    @ObservedObject var mapViewModel: MapViewModel
    
    var body: some View {
        VStack {
            // Thanh tìm kiếm - simplified version
            SearchField(
                searchText: $mapViewModel.searchText,
                viewModel: mapViewModel
            )
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Spacer()
            
            // Nút định vị và nút tìm kiếm
            HStack {
                Spacer()
                
                VStack(spacing: 10) {
                    // Nút tìm kiếm
                    Button(action: {
                        // Hiển thị sheet hoặc modal tìm kiếm địa điểm
                        // Hoặc có thể focus vào thanh tìm kiếm
                        let _ = UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 16)
                    
                    // Nút định vị
                    Button(action: {
                        print("🔍 Centering on user location")
                        mapViewModel.centerOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .padding(12)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 2)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 16)
            }
            
            Text("Nhấn vào bản đồ để chọn vị trí hoặc tìm kiếm địa điểm")
                .font(.system(size: 14, weight: .medium))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.bottom, 20)
        }
        .onAppear {
            print("👁️ MapSinglePointView appeared")
            setupMapTapListener()
        }
    }
    
    private func setupMapTapListener() {
        // Đảm bảo map đã sẵn sàng để nhận tap
        if mapViewModel.isStyleLoaded {
            print("✅ Map style is loaded and ready for interaction")
            
            // Kiểm tra xem isMapReady đã được thiết lập chưa
            if mapViewModel.isMapReady {
                print("✅ Map is also ready (isMapReady = true)")
            } else {
                print("⚠️ Map style is loaded but isMapReady = false, forcing isMapReady = true")
                mapViewModel.isMapReady = true
            }
            
            // Thiết lập callback để xử lý tap trên bản đồ
            mapViewModel.onMapTapped = { coordinate in
                print("🎯 Map tapped at: \(coordinate.latitude), \(coordinate.longitude)")
                
                // Thêm marker và tìm địa chỉ
                self.mapViewModel.addMarker(at: coordinate, title: "Vị trí đã chọn")
                print("📍 Marker added at: \(coordinate.latitude), \(coordinate.longitude)")
                
                // Zoom vào vị trí đó
                self.mapViewModel.mapViewManager.moveCamera(to: coordinate, zoom: 15)
                print("🔍 Zoomed to selected location")
            }
        } else {
            print("⏳ Map style not loaded yet, waiting...")
            // Đăng ký thông báo khi style được tải xong
            NotificationCenter.default.post(name: Notification.Name("RequestSinglePointModeSetup"), object: nil)
        }
    }
}

#Preview {
    MapSinglePointView(mapViewModel: MapViewModel())
} 
