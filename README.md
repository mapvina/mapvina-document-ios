# TrackAsia iOS SDK

## Giới thiệu

TrackAsia iOS SDK là một thư viện bản đồ mạnh mẽ cho ứng dụng iOS, được xây dựng bằng SwiftUI và cung cấp giải pháp bản đồ chất lượng cao với nhiều tính năng tiên tiến. Thư viện này cho phép bạn tích hợp bản đồ tương tác, theo dõi vị trí người dùng và tùy chỉnh giao diện bản đồ một cách linh hoạt trong ứng dụng iOS của bạn.

### Lợi ích chính:

* Hiệu suất cao và tối ưu cho thiết bị iOS
* Xây dựng với SwiftUI hiện đại
* Tích hợp dễ dàng với các ứng dụng iOS
* Nhiều tùy chọn tùy biến giao diện và tính năng
* Hỗ trợ theo dõi vị trí người dùng thời gian thực

## Mục Lục

1. Yêu Cầu Hệ Thống
2. Cài Đặt
3. Triển Khai Cơ Bản
4. Tính Năng Nâng Cao
5. Cấu Hình
6. Xử Lý Sự Cố
7. Tài Liệu Tham Khảo

## Yêu cầu hệ thống

### iOS
* iOS 14.0 trở lên
* Xcode 14.0 trở lên
* Swift 5.0 trở lên
* CocoaPods hoặc Swift Package Manager

## Cài đặt

### 1. Sử dụng Package Dependencies

1. Trong Xcode, mở Project Settings
2. Chọn tab Package Dependencies
3. Click "+" để thêm package mới
4. Nhập URL repository:
```
https://github.com/track-asia/trackasia-gl-native-distribution
```
5. Chọn version: `2.0.3`

### 2. Thêm thư viện Navigation

1. Thêm trackasia-ios-navigation vào project:
<img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_add_1a.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_add_2a.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_add_3.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_add_4.png" alt="ios">

2. Copy thư mục libs:
   - Copy toàn bộ thư mục `libs` vào project của bạn
   - Đảm bảo thêm các file vào target của project

3. Xử lý conflict (nếu có):
```bash
# Xóa thư mục derived data nếu gặp vấn đề về thư viện
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### 3. Sử dụng CocoaPods

Thêm vào Podfile:

```ruby
pod 'TrackAsiaGL'
pod 'Alamofire'
```

Sau đó chạy:

```bash
pod install
```

### 4. Cấu hình quyền

Thêm các quyền sau vào `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí của bạn để hiển thị trên bản đồ</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền truy cập vị trí của bạn để hiển thị trên bản đồ</string>
```

## Sử dụng cơ bản

### 1. Import thư viện
```swift
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
```

### 2. Khởi tạo và cấu hình MapView
```swift
// Khai báo MapView
var mapView: NavigationMapView? {
    didSet {
        oldValue?.removeFromSuperview()
        if let mapView = mapView {
            configureMapView(mapView)
            view.insertSubview(mapView, belowSubview: longPressHintView)
        }
    }
}

// Khởi tạo MapView với style mặc định
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.mapView = NavigationMapView(
        frame: view.bounds, 
        styleURL: URL(string: "https://maps.track-asia.com/styles/v1/-streets.json?key=public")
    )
}
```

### 3. Hiển thị bản đồ với SwiftUI

```swift
import SwiftUI
import TrackAsia

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        MapViewController(viewModel: viewModel)
            .onAppear {
                viewModel.prepareForModeChange()
                viewModel.mode = .singlePoint
            }
            .edgesIgnoringSafeArea(.all)
    }
}
```

### 4. Thêm tính năng tìm kiếm địa điểm

```swift
struct AddressSearchView: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        TextField("Nhập địa chỉ", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
}
```

### 5. Theo dõi vị trí người dùng

```swift
viewModel.centerOnUserLocation()
```

## Tính năng demo

Ứng dụng demo bao gồm các tính năng chính:
- Single Point: Hiển thị marker đơn
- Way Point: Hiển thị tuyến đường
- Cluster: Nhóm các điểm marker
- Animation: Hiệu ứng chuyển động
- Feature: Các tính năng bản đồ nâng cao

<p align="center">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_1.png" alt="IOS" width="18%">   
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_2.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_3.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_4.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_5.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_6.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/trackasia-document/-/raw/master/images/ios_7.png" alt="IOS" width="18%">
</p>

## Thư viện Core và Tài nguyên

### Core Libraries
- [TrackAsia Navigation iOS](https://github.com/track-asia/trackasia-navigation-ios)
  - Thư viện điều hướng và chỉ đường
  - Hỗ trợ turn-by-turn navigation
  - Tích hợp giao diện điều hướng

- [TrackAsia Native](https://github.com/track-asia/trackasia-native)
  - Core engine của bản đồ
  - Xử lý render map tiles
  - Quản lý vector tiles

- [TrackAsia Directions](https://github.com/track-asia/trackasia-directions-swift)
  - API chỉ đường
  - Tìm đường tối ưu
  - Hỗ trợ nhiều phương tiện di chuyển

- [TrackAsia Polyline](https://github.com/track-asia/trackasia-polyline)
  - Vẽ và quản lý polyline
  - Encode/decode tọa độ
  - Tối ưu hiển thị đường đi

- [TrackAsia Extension](https://github.com/track-asia/trackasia-annotation-extension)
  - Các extension mở rộng
  - Công cụ annotation
  - Tùy chỉnh marker và overlay

## Xử lý lỗi phổ biến

1. **Bản đồ không hiển thị**
   - Kiểm tra API key đã được cấu hình đúng
   - Xác nhận kết nối internet
   - Kiểm tra URL style map hợp lệ

2. **Vị trí người dùng không hiển thị**
   - Kiểm tra quyền truy cập vị trí đã được cấp
   - Xác nhận Location Services đã được bật
   - Kiểm tra cấu hình trong Info.plist

3. **Marker không hiển thị**
   - Xác nhận tọa độ marker hợp lệ
   - Kiểm tra viewModel đã được khởi tạo đúng
   - Đảm bảo marker nằm trong vùng nhìn thấy của camera

### Mẹo Debug

* Sử dụng print() để theo dõi các sự kiện bản đồ
* Kiểm tra thông báo lỗi trong Console
* Xác minh tất cả dependencies đã được cài đặt đúng cách

### Lưu ý quan trọng
1. Luôn kiểm tra version compatibility giữa các thư viện
2. Cấu hình quyền truy cập vị trí trong Info.plist
3. Test kỹ các tính năng trên nhiều thiết bị
4. Tối ưu hiệu năng khi sử dụng nhiều tính năng cùng lúc

## Đóng góp

Chúng tôi rất hoan nghênh mọi đóng góp cho dự án. Nếu bạn muốn đóng góp:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit thay đổi (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## Giấy phép

TrackAsia iOS SDK được phát hành dưới giấy phép MIT. Xem file LICENSE để biết thêm chi tiết.

## Liên hệ

* Website: [https://track-asia.com](https://track-asia.com)
* GitHub: [https://github.com/track-asia](https://github.com/track-asia)
* Email: support@track-asia.com

## Các bước cài đặt nhanh

1. Pod install
2. Chạy file TrackAsiaLive.xcworkspace

