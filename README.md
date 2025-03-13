# **TRACK ASIA iOS INTEGRATION GUIDE - Version 2** 

## Tích hợp TrackAsia Map vào dự án iOS

### 1. Cài đặt và cấu hình thư viện
#### 1.1. Thêm Package Dependencies
1. Trong Xcode, mở Project Settings
2. Chọn tab Package Dependencies
3. Click "+" để thêm package mới
4. Nhập URL repository:
```
https://github.com/track-asia/trackasia-gl-native-distribution
```
5. Chọn version: `2.0.3`

#### 1.2. Thêm thư viện Navigation
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

### 2. Triển khai MapView
#### 2.1. Import thư viện
```swift
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
```

#### 2.2. Khởi tạo và cấu hình MapView
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

### 3. Tính năng demo
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

### 4. Thư viện Core và Tài nguyên

#### Core Libraries
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

#### Lưu ý quan trọng
1. Luôn kiểm tra version compatibility giữa các thư viện
2. Cấu hình quyền truy cập vị trí trong Info.plist
3. Test kỹ các tính năng trên nhiều thiết bị
4. Tối ưu hiệu năng khi sử dụng nhiều tính năng cùng lúc
