# TrackAsia iOS Demo

## Cập nhật cấu trúc mã nguồn

### Tổng hợp các file utils

Để dễ dàng quản lý và bảo trì mã nguồn, các file utils đã được tổng hợp vào file `MapViewController.swift`. Cụ thể:

1. Từ thư mục `TrackAsia/Utils/`:
   - `MapUtils.swift`: Chứa các hàm tiện ích để xử lý thông tin bản đồ theo quốc gia

2. Từ thư mục `TrackAsia/mapview/utils/`:
   - `ContrySettings.swift`: Quản lý cài đặt quốc gia
   - `LocationManager.swift`: Quản lý vị trí người dùng

3. Các lớp khác đã được tổng hợp:
   - `MapViewManager`: Quản lý hiển thị bản đồ
   - `MarkerManager`: Quản lý các điểm đánh dấu trên bản đồ
   - `AddressRepository`: Xử lý tìm kiếm địa chỉ
   - `GeocodingRepository`: Xử lý chuyển đổi tọa độ thành địa chỉ
   - `AddressModel` và `AddressResponse`: Mô hình dữ liệu địa chỉ

### Lợi ích của việc tổng hợp

1. **Dễ bảo trì**: Tất cả các chức năng liên quan đến bản đồ được tập trung vào một file duy nhất
2. **Giảm phụ thuộc**: Giảm sự phụ thuộc giữa các file
3. **Dễ mở rộng**: Dễ dàng thêm chức năng mới vào hệ thống bản đồ
4. **Dễ hiểu**: Cấu trúc mã nguồn rõ ràng với các phần được đánh dấu bằng MARK

### Cách sử dụng

Để sử dụng các chức năng bản đồ, chỉ cần import file `MapViewController.swift` vào project của bạn. Tất cả các lớp và chức năng cần thiết đều có sẵn trong file này.

```swift
import SwiftUI

struct YourView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        MapViewController(viewModel: viewModel)
    }
} 