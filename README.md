# TrackAsia Map iOS SDK V2 — README tổng hợp 

- Hướng dẫn tích hợp vào dự án iOS (SPM, CocoaPods, hoặc libs nội bộ)
- Bổ sung các phần còn thiếu thường gặp khi triển khai thực tế
- Liệt kê lỗi thường gặp và cách khắc phục


## 1) Tổng quan TrackAsia Map SDK

TrackAsia Map cung cấp bộ SDK bản đồ cho iOS, bao gồm:
- Engine kết xuất bản đồ vector, quản lý tiles, render mượt với hiệu năng cao
- API định tuyến, điều hướng turn-by-turn (Navigation)
- Annotation, polyline, polygon, clustering, animation, 3D buildings, heatmap
- Khả năng tuỳ biến theme/style, biểu tượng, branding

Thành phần chính (tham khảo repo):
- TrackAsia Native: Core engine và render tiles
- TrackAsia Navigation iOS: UI và logic điều hướng turn-by-turn
- TrackAsia Directions (Swift): API tính toán tuyến đường
- TrackAsia Polyline: Encode/decode/vẽ polyline
- TrackAsia Annotation Extension: Annotation, marker, overlay nâng cao


## 2) Yêu cầu hệ thống

- iOS: 14.0+ (khuyến nghị; demo có thể chạy từ iOS 13 tuỳ cấu hình)
- Xcode: 14+ (khuyến nghị)
- Swift: 5.7+
- Quyền hệ thống: Quyền truy cập vị trí (When In Use/Always nếu chạy navigation nền)


## 3) Cài đặt và tích hợp SDK

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

### 2.2. CocoaPods

Thêm vào Podfile:
```ruby
platform :ios, '14.0'
use_frameworks!

target 'YourApp' do
  pod 'TrackAsia', '~> 2.0.3'
  pod 'MapboxDirections'
  pod 'MapboxCoreNavigation'
  pod 'MapboxNavigation'
end
```
Sau đó chạy:
```
pod repo update
pod install
```
Mở workspace (.xcworkspace) để build.

2. Copy thư mục libs:
   - Copy toàn bộ thư mục `libs` vào project của bạn
   - Đảm bảo thêm các file vào target của project

3. Xử lý conflict (nếu có):
```bash
# Xóa thư mục derived data nếu gặp vấn đề về thư viện
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

## 2.3) Cấu hình Info.plist và quyền hệ thống

Thêm các khoá sau tùy nhu cầu:
- NSLocationWhenInUseUsageDescription: Mô tả vì sao ứng dụng cần vị trí
- NSLocationAlwaysAndWhenInUseUsageDescription: Nếu cần điều hướng nền
- NSLocationTemporaryUsageDescriptionDictionary: Nếu dùng iOS 14+ cần truy cập chính xác tạm thời
- UIBackgroundModes (location): Nếu muốn theo dõi vị trí nền khi điều hướng

Ví dụ nội dung mô tả: “Ứng dụng cần truy cập vị trí để hiển thị và điều hướng trên bản đồ.”


### 2.4) Khóa truy cập và Style URL bản đồ

- Sử dụng style URL từ máy chủ TrackAsia, ví dụ:
```
https://maps.track-asia.com/styles/v1/-streets.json?key={{TRACKASIA_MAP_KEY}}
```
- Thay {{TRACKASIA_MAP_KEY}} bằng khoá thực tế của bạn (đừng hardcode vào code nguồn công khai).
- Đảm bảo key có quyền truy cập tiles trên môi trường của bạn.



### 2. Triển khai MapView
#### 2.1. Import thư viện
```swift
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
```

### 2.2. Khởi tạo và cấu hình MapView với NavigationMapView (ví dụ nhanh)
```swift
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class MapViewController: UIViewController {
    var mapView: NavigationMapView?

    var mapView: NavigationMapView? {
      didSet {
          oldValue?.removeFromSuperview()
          if let mapView = mapView {
              configureMapView(mapView)
              view.insertSubview(mapView, belowSubview: longPressHintView)
          }
      }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let styleURL = URL(string: "https://maps.track-asia.com/styles/v1/-streets.json?key={{TRACKASIA_MAP_KEY}}")
        let mv = NavigationMapView(frame: view.bounds, styleURL: styleURL)
        mapView = mv
        view.insertSubview(mv, at: 0)
    }
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

### 5. Gợi ý mở rộng/tùy biến

- Thêm tab mới: tạo View mới, đăng ký trong BottomBarView và ContentView
- Tích hợp tìm kiếm riêng: mở rộng MapViewModel và thay AddressSearchView
- Thay đổi logic cluster: sửa ClusterView.swift hoặc nguồn dữ liệu GeoJSON
- Tích hợp theme động: chuyển đổi styleURL theo quốc gia/thời tiết/thời điểm


## 6. Tham khảo thư viện (repos)

- TrackAsia Navigation iOS: UI điều hướng, turn-by-turn, tích hợp sẵn giao diện
- TrackAsia Native: Engine bản đồ, render tiles
- TrackAsia Directions (Swift): API chỉ đường, nhiều cấu hình phương tiện
- TrackAsia Polyline: Encode/decode/vẽ polyline
- TrackAsia Annotation Extension: Công cụ annotation, tuỳ chỉnh marker/overlay


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
