# MapVina Map iOS SDK V2 — README tổng hợp 

- Hướng dẫn tích hợp vào dự án iOS (SPM, CocoaPods, hoặc libs nội bộ)
- Bổ sung các phần còn thiếu thường gặp khi triển khai thực tế
- Liệt kê lỗi thường gặp và cách khắc phục


## 1) Tổng quan MapVina Map SDK

MapVina Map cung cấp bộ SDK bản đồ cho iOS, bao gồm:
- Engine kết xuất bản đồ vector, quản lý tiles, render mượt với hiệu năng cao
- API định tuyến, điều hướng turn-by-turn (Navigation)
- Annotation, polyline, polygon, clustering, animation, 3D buildings, heatmap
- Khả năng tuỳ biến theme/style, biểu tượng, branding

Thành phần chính (tham khảo repo):
- MapVina Native: Core engine và render tiles
- MapVina Navigation iOS: UI và logic điều hướng turn-by-turn
- MapVina Directions (Swift): API tính toán tuyến đường
- MapVina Polyline: Encode/decode/vẽ polyline
- MapVina Annotation Extension: Annotation, marker, overlay nâng cao


## 2) Yêu cầu hệ thống

- **iOS**: 15.0+ (demo project), hỗ trợ iOS 14.0+ cho compatibility
- **Xcode**: 14.0+ (khuyến nghị cho các tính năng mới nhất)
- **Swift**: 5.7+ (tương thích với SwiftUI và async/await)
- **CocoaPods**: 1.16.2+ (để quản lý dependencies)
- **Quyền hệ thống**: 
  - Location (When In Use) - bắt buộc cho hiển thị vị trí
  - Location (Always) - cho navigation nền
  - Network access - cho tải map tiles và directions API


## 3) Cài đặt và tích hợp SDK

### 1. Cài đặt và cấu hình thư viện
#### 1.1. Thêm Package Dependencies
1. Trong Xcode, mở Project Settings
2. Chọn tab Package Dependencies
3. Click "+" để thêm package mới
4. Nhập URL repository:
```
https://github.com/mapvina/mapvina-gl-native-distribution
```
5. Chọn version: `1.0.0`

#### 1.2. Thêm MapVina Navigation iOS

**Cách 1: Swift Package Manager (khuyến nghị)**
1. File → Add Package Dependencies
2. Nhập URL: `https://github.com/mapvina/mapvina-navigation-ios`
3. Dependency Rule: chọn branch `main` (hiện chưa có bản release gắn tag; hoặc dùng Cách 2 Local Integration như demo)
4. Add to target

**Cách 2: Local Integration (như demo)**
1. Copy thư mục `libs/mapvina-navigation-ios/` vào project
2. Thêm các module cần thiết vào target
3. Cấu hình build settings phù hợp

**Hình ảnh hướng dẫn SPM:**
<img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_add_1a.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_add_2a.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_add_3.png" alt="ios"> 
<img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_add_4.png" alt="ios"> 

### 2.2. CocoaPods (Demo Project Configuration)

**Podfile thực tế từ MapVinaSample:**
```ruby
platform :ios, '15.0'

target 'MapVinaSample' do
  use_frameworks!

  pod 'Alamofire', '~> 5.10.2'
  pod 'GoogleMaps', '9.3.0'
  pod 'MapboxGeocoder.swift', '~> 0.15'
end

# Build settings tối ưu cho MapVina
post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = '$(inherited)'
            config.build_settings['ARCHS'] = 'arm64 x86_64'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
            config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
            config.build_settings['ENABLE_BITCODE'] = 'NO'
         end
    end
  end
  # ⚠️ Phải để RỖNG để map render được trên Simulator (Apple Silicon).
  # Nếu đặt "arm64, x86_64" sẽ loại kiến trúc simulator và app không build/chạy được trên máy ảo.
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = ""
  end
end
```

**Lưu ý quan trọng (khớp `demo/Podfile` thực tế):**
- **MapVina native** được nhúng qua **`libs/MapVina.xcframework`** (trong demo là symlink tới
  `mapvina-gl-native-distribution/xcframework/MapVina.xcframework`); SPM là lựa chọn thay thế cho dự án của bạn.
- **MapVina Navigation iOS** được tích hợp qua thư mục **`libs/mapvina-navigation-ios/`** (không qua CocoaPods).
- **Không** dùng `pod 'MapVina'`.
- **Pods thực tế**: `Alamofire` (networking), `GoogleMaps 9.3.0`, `MapboxGeocoder.swift ~> 0.15` (search).

**Cài đặt:**
```bash
cd demo
pod repo update
pod install
```
Mở file `.xcworkspace` để build project.

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

**Multi-Country Support (từ demo project):**
```swift
// Constants.swift - URLs theo quốc gia
static let baseurl = "https://maps.mapvina.com/"
static let baseurlSG = "https://sg-maps.mapvina.com/" 
static let baseurlTH = "https://th-maps.mapvina.com/"

// Streets (2D) — dùng key=public_key (khớp Constants.swift, đã kiểm chứng trả HTTP 200)
static let urlStyleVN = "https://maps.mapvina.com/styles/v2/streets.json?key=public_key"
static let urlStyleSG = "https://sg-maps.mapvina.com/styles/v2/streets.json?key=public_key"
static let urlStyleTH = "https://th-maps.mapvina.com/styles/v2/streets.json?key=public_key"

// Satellite/3D — dùng key=public (theo Constants.swift)
static let urlStyle3DVN = "https://tiles.mapvina.com/sats/v1/satellite/satellite.json?key=public"

// Sử dụng MapUtils để lấy URL động
let styleURL = MapUtils.urlStyle(idCountry: "vn", is3D: false)
```

**Lưu ý (đã kiểm chứng):**
- Style **streets** yêu cầu `?key=public_key` — endpoint `.../styles/v2/streets.json?key=public_key`
  trả **HTTP 200** ("MapVina Streets Style"); dùng `?key=public` cho streets trả **HTTP 500**.
- Production: thay bằng API key thực tế của bạn.
- Hỗ trợ 3 quốc gia: VN (mặc định), SG, TH; tự động đổi style theo quốc gia.



### 2. Triển khai MapView  
#### 2.1. Import thư viện (từ MapVinaSample)
```swift
import MapVina
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import SwiftUI
import CoreLocation
```

### 2.2. Khởi tạo và cấu hình MapView với NavigationMapView (ví dụ nhanh)
```swift
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

class MapViewController: UIViewController {
    var mapView: NavigationMapView?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // streets yêu cầu key=public_key (xem mục Style URL)
        let styleURL = URL(string: "https://maps.mapvina.com/styles/v2/streets.json?key=public_key")
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
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_1.png" alt="IOS" width="18%">   
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_2.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_3.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_4.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_5.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_6.png" alt="IOS" width="18%">
  <img src="https://git.advn.vn/sangnguyen/mapvina-document/-/raw/master/images/ios_7.png" alt="IOS" width="18%">
</p>

### 4. Thư viện Core và Tài nguyên

### 5. Gợi ý mở rộng/tùy biến

- Thêm tab mới: tạo View mới, đăng ký trong BottomBarView và ContentView
- Tích hợp tìm kiếm riêng: mở rộng MapViewModel và thay AddressSearchView
- Thay đổi logic cluster: sửa ClusterView.swift hoặc nguồn dữ liệu GeoJSON
- Tích hợp theme động: chuyển đổi styleURL theo quốc gia/thời tiết/thời điểm


## 6. Tham khảo thư viện (repos)

- MapVina Navigation iOS: UI điều hướng, turn-by-turn, tích hợp sẵn giao diện
- MapVina Native: Engine bản đồ, render tiles
- MapVina Directions (Swift): API chỉ đường, nhiều cấu hình phương tiện
- MapVina Polyline: Encode/decode/vẽ polyline
- MapVina Annotation Extension: Công cụ annotation, tuỳ chỉnh marker/overlay


#### Core Libraries
- [MapVina Navigation iOS](https://github.com/mapvina/mapvina-navigation-ios)
  - Thư viện điều hướng và chỉ đường
  - Hỗ trợ turn-by-turn navigation
  - Tích hợp giao diện điều hướng

- [MapVina Native](https://github.com/mapvina/mapvina-native)
  - Core engine của bản đồ
  - Xử lý render map tiles
  - Quản lý vector tiles

- [MapVina Navigation iOS](https://github.com/mapvina/mapvina-navigation-ios)
  - API chỉ đường và điều hướng
  - Vẽ/quản lý polyline, encode/decode tọa độ
  - Tìm đường tối ưu, hỗ trợ nhiều phương tiện

- [MapVina GL Native Distribution](https://github.com/mapvina/mapvina-gl-native-distribution)
  - Annotation, marker và overlay
  - Các extension mở rộng trên core SDK

#### Lưu ý quan trọng
1. Luôn kiểm tra version compatibility giữa các thư viện
2. Cấu hình quyền truy cập vị trí trong Info.plist
3. Test kỹ các tính năng trên nhiều thiết bị
4. Tối ưu hiệu năng khi sử dụng nhiều tính năng cùng lúc


## 7) Kiểm chứng Build & Runtime

Tài liệu này đã được đồng bộ với `demo/` và **kiểm chứng bằng build + chạy trên iOS Simulator**.

### iOS — chạy được (đã kiểm chứng)
- Môi trường: **Xcode 26.4**, `MapVinaSample.xcworkspace` (CocoaPods: `Alamofire`, `GoogleMaps 9.3.0`,
  `MapboxGeocoder.swift 0.15`), MapVina native qua `libs/MapVina.xcframework` (có slice
  `ios-arm64_x86_64-simulator`), navigation qua `libs/mapvina-navigation-ios/`.
- `xcodebuild ... -sdk iphonesimulator -destination 'iPhone 16'` → **BUILD SUCCEEDED**.
- Cài + chạy trên iPhone 16 simulator (iOS 18.6): app khởi động, **style "streets" của MapVina
  render đúng** (không crash). Ảnh: `demo/simulator_ios_map_verification.png`.
- **Không phát hiện lỗi API key** như phía Flutter/Android — vì iOS nạp style trực tiếp từ URL
  đã kèm `?key=public_key` (MapLibre iOS không bắt buộc set key qua `MLNSettings`).

### Android — không áp dụng
- Repo này là **SDK/tài liệu iOS thuần** (không có target Android). Phần Android được xử lý ở các
  repo riêng (`mapvina-document-android`, `mapvina-document-flutter`).

### Điểm cần lưu ý (đã kiểm chứng bằng HTTP)
- `styles/v2/streets.json?key=public_key` → **HTTP 200** (style hợp lệ). `?key=public` → **HTTP 500**.
  ⇒ Streets phải dùng `public_key` (đã sửa trong tài liệu cho khớp `Constants.swift`).
- Endpoint satellite `tiles.mapvina.com/.../satellite.json?key=public` hiện trả **HTTP 500** khi
  kiểm tra trực tiếp — chế độ satellite/3D **chưa** được kiểm chứng runtime (mặc định demo dùng streets 2D).

### Chưa kiểm chứng trong môi trường này
- Điều hướng turn-by-turn, geocoding/Directions, chế độ satellite/3D, và chạy trên thiết bị thật
  (phụ thuộc mạng + khoá hợp lệ) — chỉ mô tả theo mã nguồn.
