//
//  AddressSearchView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia

struct AddressSearchView: View {
    @Binding var searchText: String
    @StateObject private var viewModel: MapViewModel
    @State private var isListVisible = false
    @FocusState private var isTextFieldFocused: Bool
    @StateObject var addressRepository = AddressRepository()
    @State private var debounceTask: DispatchWorkItem?
    @State private var errorMessage: String?
    
    // Tham chiếu đến ContentView cha để hiển thị toast
    @Environment(\.self) var environment
    
    init(searchText: Binding<String>, viewModel: MapViewModel) {
        self._searchText = searchText
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .trailing) {
                TextField("Nhập địa chỉ hoặc tên địa điểm", text: $searchText, onEditingChanged: { isEditing in
                    isListVisible = isEditing
                }, onCommit: {
                    isListVisible = false
                    if !searchText.isEmpty {
                        addressRepository.fetchAddresses(with: searchText)
                    }
                })
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
                .focused($isTextFieldFocused)
                .onChange(of: searchText) { newValue in
                    if newValue.isEmpty {
                        addressRepository.addresses = []
                        isListVisible = false
                        return
                    }
                    
                    // Tìm kiếm khi ngừng gõ 0.3 giây
                    debounceTask?.cancel()
                    let task = DispatchWorkItem {
                        if searchText == newValue && newValue.count >= 2 {
                            // Đặt trạng thái isListVisible = true trước khi gọi API
                            isListVisible = true
                            
                            // Xử lý tìm kiếm với error handling
                            do {
                                addressRepository.fetchAddresses(with: newValue)
                                // Xóa lỗi nếu thành công
                                self.errorMessage = nil
                            } catch {
                                // Ghi lại lỗi nếu có
                                print("Error searching: \(error)")
                                self.errorMessage = "Lỗi khi tìm kiếm: \(error.localizedDescription)"
                            }
                        }
                    }
                    debounceTask = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
                }
                
                if addressRepository.isLoading {
                    ProgressView()
                        .padding(.trailing, 8)
                } else if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        addressRepository.addresses = []
                        isListVisible = false
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                }
            }
            
            // Hiển thị kết quả tìm kiếm từ API
            if isListVisible && !searchText.isEmpty {
                // Hiển thị loading
                if addressRepository.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .frame(height: 80)
                }
                // Hiển thị lỗi nếu có
                else if let error = addressRepository.errorMessage ?? self.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.title)
                            .padding(.top)
                        
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .frame(height: 120)
                }
                // Hiển thị kết quả
                else if !addressRepository.addresses.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(addressRepository.addresses, id: \.id) { suggestion in
                                Button(action: {
                                    selectAddress(suggestion)
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.label)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(4)
                                }
                            }
                        }
                        .padding(4)
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .frame(height: min(CGFloat(addressRepository.addresses.count * 70), 300))
                }
                // Hiển thị thông báo "Đang tìm kiếm" khi chưa có kết quả
                else if searchText.count >= 2 && !addressRepository.isLoading {
                    Text("Không tìm thấy địa điểm nào phù hợp")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .frame(height: 60)
                }
            }
        }
    }
    
    private func selectAddress(_ suggestion: AddressModel) {
        searchText = suggestion.name
        isListVisible = false
        isTextFieldFocused = false
        
        if suggestion.coordinates.count >= 2 {
            // Lưu ý: Coordinates có thể có thứ tự [longitude, latitude] từ GeoJSON
            // Đảm bảo thứ tự đúng để tránh địa điểm bị sai
            let latitude = suggestion.coordinates.count > 1 ? suggestion.coordinates[1] : 0
            let longitude = suggestion.coordinates.count > 0 ? suggestion.coordinates[0] : 0
            
            let coordinate = CLLocationCoordinate2D(
                latitude: latitude,
                longitude: longitude
            )
            
            // Chỉ thực hiện nếu coordinate hợp lệ
            if CLLocationCoordinate2DIsValid(coordinate) {
                // Xóa tất cả các marker hiện có
                viewModel.clearMap()
                
                // Thêm đánh dấu tại vị trí mới
                viewModel.addMarker(at: coordinate, title: suggestion.label)
                
                // Hiển thị toast thông báo
                viewModel.showToastMessage("Đã chọn: \(suggestion.label)")
                
                // Di chuyển bản đồ đến vị trí đã chọn và zoom gần hơn
                viewModel.moveCamera(to: coordinate, zoom: 15)
            }
        }
    }
} 