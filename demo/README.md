# TrackAsia iOS Demo

TrackAsia iOS Demo là một ứng dụng mẫu minh họa các tính năng chính của thư viện TrackAsia cho iOS. Ứng dụng bao gồm nhiều chế độ xem bản đồ khác nhau, mỗi chế độ tập trung vào một tính năng cụ thể.

## Các Tính Năng Chính

### 1. Chế Độ Single Point
- Cho phép người dùng chọn một điểm trên bản đồ
- Hiển thị thông tin địa chỉ của điểm được chọn
- Tự động di chuyển camera đến vị trí đã chọn

### 2. Chế Độ Waypoint
- Cho phép người dùng chọn nhiều điểm trên bản đồ
- Tính toán và hiển thị tuyến đường giữa các điểm
- Hiển thị thông tin khoảng cách và thời gian di chuyển
- Hỗ trợ điều hướng theo tuyến đường đã chọn

### 3. Chế Độ Cluster
- Hiển thị các điểm dữ liệu theo cụm
- Tự động nhóm các điểm gần nhau thành cluster
- Hỗ trợ zoom vào cluster để xem chi tiết
- Tối ưu hiệu suất khi hiển thị nhiều điểm dữ liệu

### 4. Chế Độ Animation
- Hiển thị animation di chuyển trên tuyến đường
- Hỗ trợ play/pause animation
- Tùy chỉnh tốc độ animation
- Hiển thị vị trí hiện tại trên tuyến đường

## Hướng Dẫn Tích Hợp

### 1. Cài Đặt Dependencies
Thêm các dependencies sau vào file Podfile:

```ruby
platform :ios, '15.0'

target 'TrackAsiaSample' do
  use_frameworks!

  pod 'Alamofire', '~> 5.10.2'
  pod 'MapboxGeocoder.swift', '~> 0.15'
end
```

**Lưu ý:** TrackAsia Navigation iOS được tích hợp qua thư mục `libs/trackasia-navigation-ios` hoặc có thể cài đặt qua Swift Package Manager:
```
https://github.com/track-asia/trackasia-navigation-ios
```

### 2. Cấu Hình MapView
```swift
import TrackAsia
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

// Khởi tạo MapViewManager
let mapViewManager = MapViewManager()

// Cấu hình MapView với multi-country support
let selectedCountry = "vn" // hoặc "sg", "th"
let styleURL = MapUtils.urlStyle(idCountry: selectedCountry, is3D: false)
mapViewManager.mapView.styleURL = URL(string: styleURL)
mapViewManager.mapView.delegate = self
mapViewManager.mapView.showsUserLocation = true
mapViewManager.mapView.tracksUserCourse = false
```

### 3. Sử Dụng Các Chế Độ

#### Single Point Mode
```swift
let singlePointView = MapSinglePointView(mapViewModel: mapViewModel)
```

#### Waypoint Mode
```swift
let waypointView = MapWayPointView(mapViewModel: mapViewModel)
```

#### Cluster Mode
```swift
let clusterView = MapClusterView(mapViewModel: mapViewModel)
```

#### Animation Mode
```swift
let animationView = MapAnimationView(mapViewModel: mapViewModel)
```

### 4. Xử Lý Sự Kiện

#### Map Tap
```swift
mapViewModel.onMapTapped = { coordinate in
    // Xử lý sự kiện tap trên bản đồ
}
```

#### Route Calculation
```swift
let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in
    if let route = routes?.first {
        // Xử lý tuyến đường đã tính toán
    }
}
```

## Cấu Trúc Project

```
TrackAsiaSample/
├── TrackAsia/
│   ├── Views/
│   │   ├── Tabs/
│   │   │   ├── MapSinglePointView.swift
│   │   │   ├── MapWayPointView.swift
│   │   │   ├── MapClusterView.swift
│   │   │   ├── MapAnimationView.swift
│   │   │   └── MapFeatureView.swift
│   │   ├── Components/
│   │   │   ├── BottomBarView.swift
│   │   │   └── TopBarView.swift
│   │   ├── ContentView.swift
│   │   └── MapContainer.swift
│   ├── mapview/
│   │   ├── Feature/
│   │   │   ├── AnimationLineView.swift
│   │   │   ├── ClusterView.swift
│   │   │   └── WayPointView.swift
│   │   └── MapViewController.swift
│   ├── Utils/
│   │   ├── MapUtils.swift
│   │   └── DebugUtils.swift
│   ├── Models/
│   ├── ViewModels/
│   ├── MapViewModel.swift
│   ├── MapViewManager.swift
│   ├── Constants.swift
│   └── TrackAsiaDemoApp.swift
├── libs/
│   └── trackasia-navigation-ios/
├── Podfile
├── Podfile.lock
├── TrackAsiaSample.xcodeproj
└── TrackAsiaSample.xcworkspace
```

## Yêu Cầu Hệ Thống
- iOS 15.0 trở lên (khuyến nghị - hỗ trợ iOS 14.0+ cho một số tính năng)
- Xcode 14.0 trở lên (khuyến nghị)
- Swift 5.7 trở lên
- CocoaPods 1.16.2 (để quản lý dependencies)
- Swift Package Manager (tùy chọn)

## Giấy Phép
Dự án này được phân phối theo giấy phép MIT. Xem file LICENSE để biết thêm chi tiết.

## Giới thiệu
TrackAsia là ứng dụng iOS demo sử dụng SwiftUI và TrackAsia Map SDK, trình diễn các tính năng bản đồ hiện đại, định tuyến, clustering, tìm kiếm, và nhiều tiện ích khác. Dự án được thiết kế theo kiến trúc MVVM, dễ bảo trì, mở rộng và tích hợp vào các dự án khác.

## Tính năng chính
- **Single Point**: Thêm, di chuyển, và quản lý marker đơn lẻ trên bản đồ.
- **Multi-Point (Waypoints)**: Thêm nhiều điểm, vẽ polyline, quản lý tuyến đường.
- **Clusters**: Hiển thị hàng trăm/thousands điểm với clustering động, tối ưu hiệu suất.
- **Animation**: Vẽ và animate tuyến đường, mô phỏng di chuyển.
- **Features**: Hiển thị marker, polyline, polygon, heatmap, 3D buildings, và chế độ Compare (so sánh bản đồ).
- **Compare**: So sánh hai khu vực bản đồ, chuyển đổi nhanh giữa các chế độ hiển thị.
- **Navigation**: Định tuyến, chỉ đường, mô phỏng điều hướng với Mapbox Navigation SDK.
- **Tìm kiếm địa chỉ**: Tích hợp tìm kiếm địa điểm, reverse geocoding.
- **Tùy biến giao diện**: Hỗ trợ đổi theme, icon, màu sắc, branding.

## Chi tiết các module & tính năng

### 1. ContentView.swift
- **Entry point UI**: Quản lý navigation, tab bar, điều phối các màn hình chính.
- **Tính năng**: Quản lý tab, toast, loading, top bar, bottom bar, truyền state xuống các view con, chuyển đổi quốc gia.

### 2. BottomBarView.swift
- **Custom tab bar**: Chuyển đổi nhanh giữa các tính năng chính.
- **Tính năng**: Hiển thị icon, tên tab, trạng thái active, dễ mở rộng/thêm tab mới, tùy biến icon/màu sắc.

### 3. TopBarView.swift
- **Thanh điều hướng trên cùng**: Chọn quốc gia, hiển thị tiêu đề động.
- **Tính năng**: Dropdown chọn quốc gia, tùy biến giao diện.

### 4. MapSinglePointView.swift
- **Quản lý marker đơn lẻ**: Thêm, di chuyển, xóa marker, tự động zoom đến marker.

### 5. MapWayPointView.swift
- **Quản lý nhiều điểm (waypoints)**: Thêm/xóa waypoint, vẽ polyline, tính toán tuyến đường, tích hợp navigation.

### 6. MapClusterView.swift & mapview/Feature/ClusterView.swift
- **Clustering động**: Gom nhóm điểm, hiển thị số lượng, zoom tách nhỏ, tùy biến màu sắc/kích thước/biểu tượng.

### 7. MapAnimationView.swift & mapview/Feature/AnimationLineView.swift
- **Animation tuyến đường**: Vẽ polyline động, animate marker di chuyển, tùy biến tốc độ/màu sắc.

### 8. MapFeatureView.swift
- **Feature nâng cao**: Marker, polyline, polygon, heatmap, 3D buildings, Compare mode, bật/tắt từng loại feature.

### 9. MapViewModel.swift
- **ViewModel trung tâm**: Quản lý state, logic nghiệp vụ, mode, tích hợp tìm kiếm, geocoding, navigation, loading, toast, country.

### 10. MapContainer.swift
- **Bridge SwiftUI <-> UIViewController**: Nhúng bản đồ TrackAsia vào SwiftUI, quản lý lifecycle, kết nối gesture/sự kiện bản đồ với ViewModel.

### 11. Utils/MapUtils.swift
- **Tiện ích bản đồ**: Chuyển đổi toạ độ, style, zoom, padding, lấy style URL theo quốc gia.

### 12. Models/ & ViewModels/
- **Model dữ liệu & ViewModel**: Định nghĩa marker, toast, search result, chuẩn hoá dữ liệu, dễ tích hợp backend.

### 13. Assets.xcassets/
- **Tài nguyên giao diện**: Icon, màu sắc, logo, hình ảnh, dễ thay đổi branding/theme.
- **Biểu tượng tab**: ic_map_single, ic_map_multi, ic_map_cluster, ic_map_animation, ic_feature
- **Màu sắc chủ đạo**: colorBlue (cho UI chính)
- **Logo ứng dụng**: app_logo, AppIcon

### 14. Constants.swift và hỗ trợ đa quốc gia
- **VN**: https://maps.track-asia.com/ (mặc định)
- **SG**: https://sg-maps.track-asia.com/
- **TH**: https://th-maps.track-asia.com/
- **Key**: "public" cho demo, thay thế bằng key thực tế cho production
- **3D/Satellite**: Hỗ trợ chuyển đổi giữa 2D và 3D/satellite view

### 15. Navigation SDK (libs/trackasia-navigation-ios/)
- **Nguồn gốc**: Fork của Mapbox Navigation SDK v0.21
- **Giấy phép**: MIT/ISC (mã nguồn mở)
- **Tính năng**: Turn-by-turn navigation, simulation mode, voice guidance
- **Không có**: Telemetry, closed-source components
- **Cài đặt**: Swift Package Manager hoặc local libs

### 16. mapview/Feature/RouteHandler.swift, MarkerManager.swift, PolylineView.swift, ClusterView.swift
- **Module mở rộng bản đồ**: Quản lý route, marker, polyline, clustering
- **ClusterView**: Sử dụng GeoJSON API, tự động gom nhóm điểm, tối ưu hiệu suất
- **Tách biệt logic**: Dễ mở rộng, tái sử dụng và bảo trì
- **UIKit bridge**: Kết nối giữa SwiftUI và TrackAsia native components

## Kiến trúc dự án
- **MVVM**: Phân tách rõ View, ViewModel, Model giúp code dễ bảo trì, test, mở rộng.
- **SwiftUI**: UI hiện đại, reactive, dễ dàng custom và tái sử dụng component.
- **Modular**: Các tính năng lớn (Cluster, Feature, Navigation, ...) được tách thành module riêng.
- **Reusable Components**: BottomBarView, TopBarView, AddressSearchView, ...
- **State Management**: Sử dụng @StateObject, @ObservedObject, @Binding chuẩn SwiftUI.
- **Assets**: Tài nguyên icon, màu sắc, logo dễ thay thế.

## Hướng dẫn tích hợp vào dự án khác
### Yêu cầu
- Xcode 14 trở lên
- Swift 5.7+
- iOS 14.0+
- CocoaPods (hoặc Swift Package Manager)

### Cài đặt
1. **Thêm TrackAsia SDK và các dependency vào Podfile:**
   ```ruby
   pod 'TrackAsia', '~> 1.0'
   pod 'MapboxDirections.swift'
   pod 'MapboxCoreNavigation'
   pod 'MapboxNavigation'
   ```
   Chạy `pod install`

2. **Copy các module cần thiết:**
   - `TrackAsia/Views/` (hoặc chỉ các Tabs/Components bạn muốn)
   - `TrackAsia/MapViewModel.swift`, `TrackAsia/MapViewManager.swift`
   - `TrackAsia/mapview/Feature/ClusterView.swift` nếu dùng cluster
   - `TrackAsia/Models/`, `TrackAsia/ViewModels/`, `TrackAsia/Utils/`
   - `TrackAsia/Assets.xcassets` (icon, màu, logo...)

3. **Tùy biến giao diện:**
   - Thay logo, màu sắc trong Assets.xcassets
   - Sửa các icon, theme theo branding dự án của bạn

4. **Tích hợp vào View của bạn:**
   - Sử dụng `MapContainer`, hoặc các View như `MapSinglePointView`, `MapClusterView`, ...
   - Inject ViewModel (`MapViewModel`) vào các View cần thiết
   - Sử dụng các component như `BottomBarView`, `TopBarView` để đồng bộ UI

### Mở rộng/tùy biến
- Thêm tab mới: Tạo View mới, thêm vào BottomBarView và ContentView
- Thay đổi logic cluster: Sửa ClusterView.swift hoặc thay đổi nguồn dữ liệu GeoJSON
- Tích hợp API tìm kiếm riêng: Sửa MapViewModel và các View liên quan
- Thay đổi theme: Sửa Assets.xcassets và các file màu

## Hướng dẫn build & chạy

### Cách 1: Sử dụng CocoaPods (khuyến nghị)
1. Clone repo về máy: `git clone <repo-url>`
2. Di chuyển đến thư mục demo: `cd demo`
3. Cài đặt dependencies: `pod install`
4. Mở file `TrackAsiaSample.xcworkspace` bằng Xcode
5. Chọn target `TrackAsiaSample`
6. Build & Run trên simulator hoặc thiết bị thật

### Cách 2: Sử dụng Swift Package Manager
1. Mở `TrackAsiaSample.xcodeproj` trong Xcode
2. File -> Add Package Dependencies
3. Thêm URL: `https://github.com/track-asia/trackasia-navigation-ios`
4. Build & Run

### Lưu ý quan trọng:
- Đảm bảo Xcode 14+ và iOS 15.0+ deployment target
- Kiểm tra quyền location trong Info.plist
- Nếu gặp lỗi build, thử clean DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

## Đóng góp & liên hệ
- Đóng góp code qua Pull Request, tuân thủ coding convention trong `Views/README.md`
- Báo lỗi hoặc đề xuất tính năng mới qua Issues
- Liên hệ: [your-email@example.com] hoặc [https://github.com/trackasia/trackasia-demo-ios]

## Hướng dẫn sử dụng từng màn hình chính

### MapSinglePointView
- **Chức năng:** Chọn điểm trên bản đồ, thêm marker, tìm kiếm địa điểm, định vị nhanh.
- **Luồng hoạt động:**
  - Hiển thị thanh tìm kiếm địa chỉ.
  - Tap vào bản đồ để thêm marker, zoom đến vị trí đó.
  - Nút định vị đưa camera về vị trí người dùng.
- **Mở rộng/tùy biến:**
  - Thay thế SearchField bằng component tìm kiếm nâng cao.
  - Custom marker, tích hợp API tìm kiếm, reverse geocoding.

### MapWayPointView
- **Chức năng:** Chọn nhiều điểm, vẽ tuyến đường, tính toán route, bắt đầu navigation.
- **Luồng hoạt động:**
  - Tap lần đầu chọn điểm đi, tap lần hai chọn điểm đến.
  - Hiển thị panel waypoint, nút tính toán tuyến đường, bắt đầu navigation, reset.
  - Gọi API Directions, vẽ polyline, hiển thị khoảng cách/thời gian.
- **Mở rộng/tùy biến:**
  - Hỗ trợ multi-leg, custom UI panel, tích hợp sự kiện waypoint.

### MapFeatureView
- **Chức năng:** Bật/tắt các loại đối tượng bản đồ nâng cao: marker, polyline, polygon, heatmap, 3D buildings.
- **Luồng hoạt động:**
  - Hiển thị các nút FeatureButton cho từng loại feature.
  - Khi bật/tắt, gọi toggleFeatureOption trong ViewModel để thêm/xóa đối tượng trên bản đồ.
- **Mở rộng/tùy biến:**
  - Thêm feature mới dễ dàng, tích hợp dữ liệu ngoài, custom UI, thêm mô tả/icon.

### MapClusterView
- **Chức năng:** Hiển thị clustering động, tối ưu hiệu suất, custom icon/màu sắc.
- **Luồng hoạt động:**
  - Khi tab Clusters được chọn, khởi tạo ClusterView với mapView.
  - ClusterView tự động gom nhóm các điểm gần nhau thành cluster, hiển thị số lượng điểm.
  - Zoom vào cluster để tách nhỏ dần.
- **Mở rộng/tùy biến:**
  - Sửa ClusterView.swift để thay đổi logic gom nhóm, custom icon, màu sắc, hiệu ứng.

### MapAnimationView
- **Chức năng:** Animate tuyến đường, mô phỏng di chuyển marker, play/pause animation.
- **Luồng hoạt động:**
  - Nút play/pause để bắt đầu/dừng animation.
  - Marker di chuyển theo tuyến đường đã vẽ.
  - Nút định vị đưa camera về vị trí người dùng.
- **Mở rộng/tùy biến:**
  - Thay đổi tốc độ, màu sắc, hiệu ứng marker, animation nhiều tuyến đường.

## Dependencies và Cấu hình

### Dependencies chính (Podfile.lock)
```ruby
Alamofire (5.10.2)          # Networking  
MapboxGeocoder.swift (0.15.0) # Geocoding services
```

### TrackAsia Navigation iOS
- **Giấy phép**: MIT/ISC (mã nguồn mở hoàn toàn)
- **Nguồn gốc**: Fork của Mapbox Navigation SDK v0.21
- **Khác biệt chính**:
  - Loại bỏ telemetry và các thành phần closed-source
  - Chuyển từ Mapbox SDK sang TrackAsia Native
  - Thêm tùy chọn cấu hình cho NavigationMapView
  - Không cần API key Mapbox

### Cấu hình đa quốc gia
```swift
// Constants.swift
static let baseurl = "https://maps.track-asia.com/"
static let baseurlSG = "https://sg-maps.track-asia.com/"
static let baseurlTH = "https://th-maps.track-asia.com/"

// Cách sử dụng
let styleURL = MapUtils.urlStyle(idCountry: "vn", is3D: false)
let coordinate = MapUtils.getLatlng(idCountry: "vn")
let zoomLevel = MapUtils.zoom(idCountry: "vn")
```

### Cấu hình quyền hệ thống (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần truy cập vị trí để hiển thị và điều hướng trên bản đồ.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền vị trí để cung cấp dịch vụ điều hướng.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## Hướng dẫn tích hợp từng tính năng bản đồ

### 1. Tích hợp Single Point (MapSinglePointView)
**Mô tả:** Cho phép chọn 1 điểm trên bản đồ, thêm marker, tìm kiếm địa điểm, định vị nhanh.

**SwiftUI:**
```swift
MapSinglePointView(mapViewModel: mapViewModel)
```

**UIKit:**
Nhúng qua `UIHostingController`:
```swift
let vc = UIHostingController(rootView: MapSinglePointView(mapViewModel: mapViewModel))
self.present(vc, animated: true)
```

**Callback sự kiện:**
```swift
mapViewModel.onMapTapped = { coordinate in
    // Xử lý khi người dùng chọn vị trí
}
```

**Tuỳ biến:**
- Thay SearchField bằng component tìm kiếm nâng cao.
- Custom marker, tích hợp API tìm kiếm, reverse geocoding.

---

### 2. Tích hợp Multi-Point/Waypoints (MapWayPointView)
**Mô tả:** Chọn nhiều điểm, vẽ tuyến đường, tính toán route, bắt đầu navigation.

**SwiftUI:**
```swift
MapWayPointView(mapViewModel: mapViewModel)
```

**UIKit:**
Nhúng qua `UIHostingController`:
```swift
let vc = UIHostingController(rootView: MapWayPointView(mapViewModel: mapViewModel))
self.present(vc, animated: true)
```

**Callback sự kiện:**
```swift
mapViewModel.onMapTapped = { coordinate in
    // Xử lý khi chọn waypoint
}
```

**Tuỳ biến:**
- Hỗ trợ multi-leg, custom UI panel, tích hợp sự kiện waypoint.
- Tuỳ chỉnh logic vẽ polyline, custom marker cho từng waypoint.

---

### 3. Tích hợp Feature nâng cao (MapFeatureView)
**Mô tả:** Bật/tắt các đối tượng bản đồ nâng cao: marker, polyline, polygon, heatmap, 3D buildings.

**SwiftUI:**
```swift
MapFeatureView(mapViewModel: mapViewModel)
```

**UIKit:**
Nhúng qua `UIHostingController`:
```swift
let vc = UIHostingController(rootView: MapFeatureView(mapViewModel: mapViewModel))
self.present(vc, animated: true)
```

**Callback sự kiện:**
```swift
// Lắng nghe thay đổi feature option
viewModel.toggleFeatureOption = { featureKey in
    // Xử lý khi bật/tắt feature
}
```

**Tuỳ biến:**
- Thêm feature mới dễ dàng, tích hợp dữ liệu ngoài, custom UI, thêm mô tả/icon.
- Tuỳ chỉnh logic hiển thị đối tượng trên bản đồ qua ViewModel.

---

### 4. Tích hợp Clustering (MapClusterView)
**Mô tả:** Hiển thị clustering động, gom nhóm điểm, tối ưu hiệu suất, custom icon/màu sắc.

**SwiftUI:**
```swift
MapClusterView(mapViewModel: mapViewModel)
```

**UIKit:**
Nhúng qua `UIHostingController`:
```swift
let vc = UIHostingController(rootView: MapClusterView(mapViewModel: mapViewModel))
self.present(vc, animated: true)
```

**Callback sự kiện:**
```swift
// Lắng nghe sự kiện tap vào cluster (sửa trong ClusterView.swift)
clusterView.onClusterTapped = { cluster in
    // Xử lý zoom hoặc hiển thị chi tiết
}
```

**Clustering Configuration (ClusterView.swift):**
```swift
// Sử dụng GeoJSON từ API
let source = MLNShapeSource(
    identifier: "clusteredPorts",
    url: URL(string: "https://panel.hainong.vn/api/v2/diagnostics/pets_map.geojson")!,
    options: [
        .clustered: true, 
        .clusterRadius: 50,
        .maximumZoomLevelForClustering: 14
    ]
)

// Tự động gom nhóm dựa trên zoom level và kẻ cách
clusterLayer.circleRadius = NSExpression(format: "12 + log(point_count) * 3")
```

**Tuỳ biến:**
- Thay đổi GeoJSON source URL cho dữ liệu riêng
- Custom cluster icon, màu sắc, kích thước  
- Điều chỉnh thuật toán gom nhóm (clusterRadius, maxZoom)
- Tích hợp sự kiện tap cluster, custom popup
- Xử lý zoom tự động khi tap vào cluster

---

### 5. Navigation và Turn-by-Turn Directions
**Tích hợp Navigation SDK:**
```swift
// NavigationUIView trong MapWayPointView.swift
struct NavigationUIView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NavigationViewController {
        let navigationVC = NavigationViewController(
            dayStyle: DayStyle(demoStyle: ()), 
            nightStyle: NightStyle(demoStyle: ())
        )
        return navigationVC
    }
}

// Bắt đầu navigation với simulation
let simulatedLocationManager = SimulatedLocationManager(route: route)
simulatedLocationManager.speedMultiplier = 2.0
navigationVC.startNavigation(with: route, animated: true, locationManager: simulatedLocationManager)
```

**Tính toán tuyến đường:**
```swift
// Sử dụng Mapbox Directions API
let origin = Waypoint(coordinate: startPoint)
let destination = Waypoint(coordinate: endPoint)
let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])

Directions.shared.calculate(routeOptions) { (waypoints, routes, error) in
    if let route = routes?.first {
        self.handleSuccessfulRouteCalculation(route)
    } else {
        // Fallback với straight line
        self.drawStraightLine(from: startPoint, to: endPoint)
    }
}
```

### 6. Multi-Country Support và Dynamic Styling
**Chuyển đổi quốc gia động:**
```swift
// ContentView.swift - hỗ trợ 3 quốc gia
let countries: [String: String] = [
    "vn": "Việt Nam",
    "sg": "Singapore", 
    "th": "Thailand"
]

// Tự động cập nhật style và camera
func handleCountryChange(_ country: String) {
    let styleURL = MapUtils.urlStyle(idCountry: country, is3D: false)
    let coordinate = MapUtils.getLatlng(idCountry: country).toCLLocationCoordinate2D()
    mapViewModel.updateMap(selectedCountry: country)
}
```

**Lưu ý quan trọng:**
- Tất cả các View đều kết nối qua MapViewModel (MVVM pattern)
- MapContainer.swift là bridge giữa SwiftUI và UIKit components
- Có thể kết hợp nhiều tính năng trong một View
- Đọc kỹ callback patterns và state management để tích hợp đúng
- Kiểm tra quyền location và network permissions

---

**TrackAsia - Digital Map Platform for Asia**

## Chi Tiết Kỹ Thuật

### 1. MapViewModel
MapViewModel là trung tâm quản lý trạng thái và logic của ứng dụng. Các tính năng chính:

```swift
class MapViewModel: ObservableObject {
    @Published var mapViewManager = MapViewManager()
    @Published var mode: MapMode = .singlePoint
    @Published var selectedLocation: CLLocationCoordinate2D?
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var currentRoute: Route?
    @Published var isAnimating: Bool = false
    
    // Các phương thức chính
    func updateMode(_ newMode: MapMode)
    func addMarker(at coordinate: CLLocationCoordinate2D, title: String)
    func addWaypoint(at coordinate: CLLocationCoordinate2D)
    func calculateRoute()
    func startNavigation()
    func setupClusterPoints()
    func setupAnimationRoute()
}
```

### 2. MapViewManager
Quản lý các thao tác với bản đồ:

```swift
class MapViewManager {
    var mapView: MLNMapView
    
    // Các phương thức chính
    func moveCamera(to coordinate: CLLocationCoordinate2D, zoom: Double)
    func addPolyline(coordinates: [CLLocationCoordinate2D])
    func addAnimationPolyline(coordinates: [CLLocationCoordinate2D])
    func removeAllPolylines()
    func addAnnotation(_ annotation: MLNAnnotation)
    func removeAnnotations(_ annotations: [MLNAnnotation])
}
```

### 3. Cấu Hình Bản Đồ
Các thông số cấu hình quan trọng:

```swift
// Cấu hình MapView
mapViewManager.mapView.styleURL = URL(string: "YOUR_STYLE_URL")
mapViewManager.mapView.delegate = self
mapViewManager.mapView.showsUserLocation = true
mapViewManager.mapView.tracksUserCourse = false
mapViewManager.mapView.zoomLevel = 12
mapViewManager.mapView.minimumZoomLevel = 3
mapViewManager.mapView.maximumZoomLevel = 20
```

### 4. Xử Lý Sự Kiện Bản Đồ
Các sự kiện chính cần xử lý:

```swift
// MapViewDelegate
extension YourViewController: MLNMapViewDelegate {
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        // Xử lý khi style được tải xong
    }
    
    func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
        // Xử lý khi chọn annotation
    }
    
    func mapView(_ mapView: MLNMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // Xử lý khi tap vào bản đồ
    }
}
```

### 5. Tích Hợp Navigation
Cấu hình và sử dụng Navigation SDK:

```swift
// Cấu hình Navigation
let navigationOptions = NavigationOptions()
navigationOptions.directions = Directions.shared
navigationOptions.locationManager = SimulatedLocationManager()

// Khởi tạo NavigationViewController
let navigationVC = NavigationViewController(
    route: route,
    routeOptions: routeOptions,
    navigationOptions: navigationOptions
)

// Bắt đầu điều hướng
navigationVC.startNavigation()
```

### 6. Tích Hợp Clustering
Cấu hình và sử dụng clustering:

```swift
// Cấu hình ClusterView
let clusterView = ClusterView(mapView: mapView)
clusterView.setupClusters()

// Thêm điểm vào cluster
let point = MLNPointFeature()
point.coordinate = coordinate
clusterView.addPoint(point)

// Xử lý sự kiện tap cluster
clusterView.onClusterTapped = { cluster in
    // Xử lý khi tap vào cluster
}
```

### 7. Tích Hợp Animation
Cấu hình và sử dụng animation:

```swift
// Cấu hình AnimationLineView
let animationView = PolylineView(coordinates: routeCoordinates)
animationView.addPolyline(to: mapView.style!, mapview: mapView)

// Bắt đầu animation
animationView.startAnimation()

// Dừng animation
animationView.stopAnimation()
```

## Hướng Dẫn Debug

### 1. Debug MapView
```swift
// Bật chế độ debug
mapViewManager.mapView.debugMask = [.tileBoundaries, .tileInfo, .timestamps]

// Log các sự kiện quan trọng
print("MapView state: \(mapViewManager.mapView.state)")
print("Current zoom: \(mapViewManager.mapView.zoomLevel)")
print("Current center: \(mapViewManager.mapView.centerCoordinate)")
```

### 2. Debug Navigation
```swift
// Bật log navigation
NavigationSettings.shared.loggingLevel = .debug

// Log các sự kiện navigation
print("Navigation state: \(navigationVC.state)")
print("Current step: \(navigationVC.currentStep)")
print("Remaining distance: \(navigationVC.remainingDistance)")
```

### 3. Debug Clustering
```swift
// Bật log clustering
clusterView.debugMode = true

// Log thông tin cluster
print("Cluster count: \(clusterView.clusterCount)")
print("Point count: \(clusterView.pointCount)")
```

## Tối Ưu Hiệu Năng

### 1. Tối ưu bộ nhớ và hiệu suất
```swift
// Giải phóng tài nguyên khi chuyển mode
func prepareForModeChange() {
    clearAllAnnotations()
    stopAnimating()
    mapViewManager.removeAllPolylines()
    
    // Xóa cluster resources
    if let clusterView = self.clusterView {
        clusterView.cleanup()
    }
}

// Tối ưu URLSession cho network requests
private func configureURLSessionTimeouts() {
    URLSessionConfiguration.default.timeoutIntervalForResource = 60.0
    URLSessionConfiguration.default.timeoutIntervalForRequest = 60.0
}

// Cleanup resources trong ClusterView
public func cleanup() {
    cleanupExistingLayers()
    mapView.delegate = previousDelegate
    self.mapView = nil
    self.previousDelegate = nil
}
```

### 2. Tối ưu hiển thị
```swift
// Sử dụng level of detail (LOD)
mapViewManager.mapView.minimumZoomLevel = 3
mapViewManager.mapView.maximumZoomLevel = 20

// Tối ưu hiển thị cluster
clusterView.maxZoomLevel = 18
clusterView.minZoomLevel = 3
```

### 3. Tối ưu animation
```swift
// Sử dụng CADisplayLink cho animation mượt
let displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
displayLink.add(to: .main, forMode: .common)
```

## Xử Lý Lỗi

### 1. Xử lý lỗi bản đồ
```swift
func mapView(_ mapView: MLNMapView, didFailToLoad style: MLNStyle, error: Error) {
    print("Failed to load style: \(error.localizedDescription)")
    // Xử lý lỗi và thử lại
    retryLoadingStyle()
}
```

### 2. Xử lý lỗi navigation
```swift
func navigationViewController(_ navigationViewController: NavigationViewController, 
                           didFailToReroute error: Error) {
    print("Failed to reroute: \(error.localizedDescription)")
    // Xử lý lỗi và thử lại
    retryRerouting()
}
```

### 3. Xử lý lỗi clustering
```swift
func clusterView(_ clusterView: ClusterView, didFailToCluster error: Error) {
    print("Failed to cluster: \(error.localizedDescription)")
    // Xử lý lỗi và thử lại
    retryClustering()
}
```

## Best Practices

### 1. Quản lý bộ nhớ
- Sử dụng weak reference cho delegate
- Giải phóng tài nguyên khi view disappear
- Sử dụng autoreleasepool cho các thao tác nặng

### 2. Xử lý sự kiện
- Sử dụng DispatchQueue.main cho các thao tác UI
- Tránh block main thread
- Sử dụng completion handler thay vì delegate khi có thể

### 3. Tối ưu code
- Sử dụng lazy loading cho các thành phần nặng
- Cache dữ liệu khi cần thiết
- Sử dụng background thread cho các thao tác tính toán