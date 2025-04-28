# TrackAsia Project - Cursor Rules

## Project Overview
TrackAsia là một ứng dụng iOS demo sử dụng SwiftUI và TrackAsia Map SDK để hiển thị và tương tác với bản đồ. Ứng dụng đã được refactor theo kiến trúc MVVM với cấu trúc modular để dễ dàng bảo trì và mở rộng.

## Coding Standards

### 1. Kiến Trúc & Tổ Chức File
- Tuân thủ kiến trúc MVVM (Model-View-ViewModel)
- Mỗi file chỉ định nghĩa một component hoặc một chức năng rõ ràng
- Phân tách logic UI và business logic bằng cách sử dụng ViewModel
- Sắp xếp code theo thứ tự:
  ```
  // MARK: - Enums/Constants
  // MARK: - Properties
  // MARK: - Initialization
  // MARK: - View Lifecycle
  // MARK: - Public Methods
  // MARK: - Private Methods
  // MARK: - Event Handlers
  ```

### 2. Quy Tắc Đặt Tên
- Sử dụng camelCase cho biến, thuộc tính và hàm (`mapViewModel`, `updateScreenTitle()`)
- Sử dụng PascalCase cho tên classes, structs, enums (`ContentView`, `MapViewModel`)
- Tên file phải trùng với tên của class/struct chính chứa trong file
- Tên hàm phải mô tả rõ chức năng, bắt đầu bằng động từ (`updateMap()`, `handleTabSelection()`)

### 3. SwiftUI Conventions
- Sử dụng `@StateObject` cho ViewModel được tạo trong view
- Sử dụng `@ObservedObject` cho ViewModel được truyền từ bên ngoài
- Sử dụng `@Binding` khi cần truyền state có thể thay đổi xuống các child view
- Đặt tên state và binding rõ ràng để thể hiện mục đích (`selectedTab`, `isLoading`)
- Sử dụng composition để tạo giao diện từ các components nhỏ hơn

### 4. Xử Lý State & Side Effects
- Sử dụng `onChange()` để phản ứng với thay đổi của state
- Sử dụng `onAppear()` và `onDisappear()` để thực hiện setup/cleanup
- Đảm bảo sử dụng `DispatchQueue.main.async` cho các cập nhật UI
- Thêm `print` statements với emoji để debug (🔄, 📱, 🏷️)

### 5. Map Interactions
- Tất cả tương tác với bản đồ phải thông qua `MapViewModel`
- Đảm bảo xử lý đúng trạng thái loading của bản đồ trước khi tương tác
- Sử dụng notifications để giao tiếp giữa các components không trực tiếp liên quan
- Xử lý cleanup tài nguyên trong `deinit` để tránh memory leaks

### 6. Error Handling & Logging
- Log các sự kiện quan trọng với emoji để dễ theo dõi (🔍, ✅, ⚠️)
- Xử lý tất cả các tình huống lỗi với feedback phù hợp cho người dùng
- Sử dụng `showToast()` để hiển thị thông báo ngắn gọn cho người dùng

## File Structure

```
TrackAsia/
├── Models/
│   ├── SearchAddressModel.swift
│   └── Toast.swift
├── ViewModels/
│   ├── ContentViewModel.swift
│   ├── ContentViewCountrySettings.swift
│   └── MapViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── MapContainer.swift
│   ├── Components/
│   │   ├── AddressSearchView.swift
│   │   ├── BottomBarView.swift
│   │   └── TopBarView.swift
│   └── Tabs/
│       ├── MapSinglePointView.swift
│       ├── MapWayPointView.swift
│       ├── MapClusterView.swift
│       ├── MapAnimationView.swift
│       ├── MapFeatureView.swift
│       └── MapCompareView.swift
└── Utilities/
    ├── MapUtils.swift
    └── Constants.swift
```

## Git Rules
- Commit message phải rõ ràng, mô tả chính xác thay đổi
- Mỗi feature được phát triển trên branch riêng và merge vào main thông qua Pull Request
- Code phải được review trước khi merge

## Build & Performance
- Duy trì hiệu suất tốt bằng cách tránh không cần thiết redraw UI
- Tối ưu hóa code để giảm memory footprint
- Tránh sử dụng force unwrap (`!`) khi có thể

## Dependencies
- TrackAsia SDK: Bản đồ chính của ứng dụng
- Alamofire: Xử lý network requests
- MapboxDirections & MapboxNavigation: Chức năng định tuyến và điều hướng
- SwiftUI & Combine: Framework chính cho UI và reactive programming 