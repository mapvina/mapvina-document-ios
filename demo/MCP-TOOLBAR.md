# Hướng dẫn triển khai Top Bar và Bottom Bar từ Android sang iOS

## 1. Phân tích Top Bar (Android)

### Cấu trúc trong Android:
- Sử dụng `AppBarLayout` với `CardView` bên trong chứa các thành phần
- Thiết kế bo tròn, nổi trên màn hình (elevation)
- Có background màu xanh (`colorBlue`)

### Các thành phần chính:
1. **Logo và tên ứng dụng:**
   - Logo/icon ở góc trái
   - Text "TrackAsia" ngay bên cạnh, màu trắng, font đậm
   
2. **Tiêu đề màn hình hiện tại:**
   - Text ở giữa (như "Single Point", "Clusters",...)
   - Màu trắng, font thường
   - Được cập nhật động khi chuyển tab

3. **Chọn quốc gia (Country Selector):**
   - Nằm ở bên phải
   - Hiển thị tên quốc gia hiện tại ("Việt Nam", "Singapore", "Thailand",...)
   - Có nền màu trắng, chữ màu xanh (`colorBlue`)
   - Bo tròn viền
   - Khi nhấn vào sẽ hiển thị PopupMenu với danh sách quốc gia

### Chi tiết Code Android:
```kotlin
// Style của Top Bar
- Nền: colorBlue
- Sử dụng CardView bo tròn 16dp
- Elevation 8dp để tạo hiệu ứng nổi

// Popup menu chọn quốc gia
- Sử dụng PopupMenu khi click vào indicator quốc gia
- Menu được định nghĩa trong R.menu.toolbar_menu
- Lưu lựa chọn vào SharedPreferences
- Khi thay đổi quốc gia, cập nhật map theo urlStyle tương ứng
```

## 2. Phân tích Bottom Bar (Android)

### Cấu trúc trong Android:
- Sử dụng `BottomNavigationView` đặt trong `CardView`
- Bo tròn viền 16dp
- Elevation 8dp
- Margin cách viền màn hình 12dp

### Các thành phần chính:
1. **Menu items:**
   - 5 mục: "Single Point", "Multi-Point", "Clusters", "Animation", "Features"
   - Mỗi mục có icon riêng và tiêu đề
   - Hiển thị đầy đủ cả text (labelVisibilityMode="labeled")
   
2. **Màu sắc:**
   - Nền: colorBlue
   - Text và icon khi selected: màu trắng
   - Text và icon khi không selected: trắng transparent (80FFFFFF)

3. **Xử lý sự kiện:**
   - Khi click item, cập nhật fragment và tiêu đề màn hình
   - Mỗi item gắn với một fragment screen riêng

### Chi tiết Code Android:
```kotlin
// Style của Bottom Navigation
- Nền: colorBlue
- CardView bo tròn 16dp
- Elevation 8dp
- Margin horizontal và bottom 12dp

// Màu sắc
- Sử dụng ColorStateList để thay đổi màu khi selected
- Selected: màu trắng
- Unselected: màu trắng với alpha 0.5

// Navigation items
- Được định nghĩa trong menu/bottom_navigation.xml
- Mỗi item có ID riêng cho việc điều hướng
- Xử lý chọn item trong MainActivity.kt
```

## 3. Triển khai trong iOS

### Top Bar:
1. **Cấu trúc UI:**
```swift
// Tạo container view
let topBarContainer = UIView()
topBarContainer.backgroundColor = .clear

// Card view chứa nội dung
let topBarCard = UIView()
topBarCard.backgroundColor = UIColor(named: "colorBlue")
topBarCard.layer.cornerRadius = 16
topBarCard.layer.shadowColor = UIColor.black.cgColor
topBarCard.layer.shadowOffset = CGSize(width: 0, height: 2)
topBarCard.layer.shadowRadius = 4
topBarCard.layer.shadowOpacity = 0.2

// Logo và app name
let logoImageView = UIImageView(image: UIImage(named: "app_logo"))
logoImageView.contentMode = .scaleAspectFit
logoImageView.tintColor = .white

let appNameLabel = UILabel()
appNameLabel.text = "TrackAsia"
appNameLabel.textColor = .white
appNameLabel.font = UIFont.boldSystemFont(ofSize: 18)

// Tiêu đề màn hình
let titleLabel = UILabel()
titleLabel.text = "Single Point" // Default
titleLabel.textColor = .white
titleLabel.font = UIFont.systemFont(ofSize: 15)

// Country selector
let countryLabel = UILabel()
countryLabel.text = "Việt Nam" // Default
countryLabel.textColor = UIColor(named: "colorBlue")
countryLabel.backgroundColor = .white
countryLabel.layer.cornerRadius = 8
countryLabel.layer.masksToBounds = true
countryLabel.textAlignment = .center
countryLabel.font = UIFont.boldSystemFont(ofSize: 14)
countryLabel.isUserInteractionEnabled = true
countryLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showCountrySelector)))
```

2. **Popup Menu chọn quốc gia:**
```swift
@objc func showCountrySelector() {
    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let vietnamAction = UIAlertAction(title: "Việt Nam", style: .default) { [weak self] _ in
        self?.changeCountry(to: "vn", name: "Việt Nam")
    }
    
    let singaporeAction = UIAlertAction(title: "Singapore", style: .default) { [weak self] _ in
        self?.changeCountry(to: "sg", name: "Singapore")
    }
    
    let thailandAction = UIAlertAction(title: "Thailand", style: .default) { [weak self] _ in
        self?.changeCountry(to: "th", name: "Thailand")
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    actionSheet.addAction(vietnamAction)
    actionSheet.addAction(singaporeAction)
    actionSheet.addAction(thailandAction)
    actionSheet.addAction(cancelAction)
    
    present(actionSheet, animated: true)
}

private func changeCountry(to code: String, name: String) {
    // Lưu vào UserDefaults
    UserDefaults.standard.set(code, forKey: "country")
    
    // Cập nhật UI
    countryLabel.text = name
    
    // Cập nhật bản đồ (reload current view controller)
    refreshCurrentViewController()
}
```

### Bottom Bar:
1. **Cấu trúc UI:**
```swift
// Container cho bottom bar
let bottomBarContainer = UIView()
bottomBarContainer.backgroundColor = .clear

// Card view chứa tab bar
let bottomBarCard = UIView()
bottomBarCard.backgroundColor = UIColor(named: "colorBlue")
bottomBarCard.layer.cornerRadius = 16
bottomBarCard.layer.shadowColor = UIColor.black.cgColor
bottomBarCard.layer.shadowOffset = CGSize(width: 0, height: -2)
bottomBarCard.layer.shadowRadius = 4
bottomBarCard.layer.shadowOpacity = 0.2

// Tab bar
let tabBar = UITabBar()
tabBar.delegate = self
tabBar.backgroundColor = .clear // Để hiện màu của card
tabBar.tintColor = .white // Màu khi selected
tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.5) // Màu khi không selected

// Các items
let singlePointItem = UITabBarItem(title: "Single Point", image: UIImage(named: "ic_map_single"), tag: 0)
let multiPointItem = UITabBarItem(title: "Multi-Point", image: UIImage(named: "ic_map_multi"), tag: 1) 
let clustersItem = UITabBarItem(title: "Clusters", image: UIImage(named: "ic_map_cluster"), tag: 2)
let animationItem = UITabBarItem(title: "Animation", image: UIImage(named: "ic_map_animation"), tag: 3)
let featuresItem = UITabBarItem(title: "Features", image: UIImage(named: "ic_feature"), tag: 4)

tabBar.items = [singlePointItem, multiPointItem, clustersItem, animationItem, featuresItem]
tabBar.selectedItem = singlePointItem // Default
```

2. **Xử lý chuyển tab:**
```swift
// UITabBarDelegate
func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    switch item.tag {
    case 0:
        showViewController(SinglePointViewController())
        updateTitle("Single Point")
    case 1: 
        showViewController(MultiPointViewController())
        updateTitle("Multi-Point")
    case 2:
        showViewController(ClusterViewController())
        updateTitle("Clusters")
    case 3:
        showViewController(AnimationViewController())
        updateTitle("Animation")
    case 4:
        showViewController(FeaturesViewController())
        updateTitle("Features")
    default:
        break
    }
}

private func showViewController(_ viewController: UIViewController) {
    // Remove current child view controller
    if let currentVC = children.first {
        currentVC.willMove(toParent: nil)
        currentVC.view.removeFromSuperview()
        currentVC.removeFromParent()
    }
    
    // Add new view controller
    addChild(viewController)
    containerView.addSubview(viewController.view)
    viewController.view.frame = containerView.bounds
    viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    viewController.didMove(toParent: self)
}

private func updateTitle(_ title: String) {
    titleLabel.text = title
}
```

### Thiết lập AutoLayout:

```swift
// Đặt auto layout cho top bar
NSLayoutConstraint.activate([
    topBarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
    topBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
    topBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
    topBarContainer.heightAnchor.constraint(equalToConstant: 56),
    
    // Card bên trong
    topBarCard.topAnchor.constraint(equalTo: topBarContainer.topAnchor),
    topBarCard.leadingAnchor.constraint(equalTo: topBarContainer.leadingAnchor),
    topBarCard.trailingAnchor.constraint(equalTo: topBarContainer.trailingAnchor),
    topBarCard.bottomAnchor.constraint(equalTo: topBarContainer.bottomAnchor),
    
    // Logo
    logoImageView.leadingAnchor.constraint(equalTo: topBarCard.leadingAnchor, constant: 16),
    logoImageView.centerYAnchor.constraint(equalTo: topBarCard.centerYAnchor),
    logoImageView.widthAnchor.constraint(equalToConstant: 24),
    logoImageView.heightAnchor.constraint(equalToConstant: 24),
    
    // App name
    appNameLabel.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 8),
    appNameLabel.centerYAnchor.constraint(equalTo: topBarCard.centerYAnchor),
    
    // Title
    titleLabel.leadingAnchor.constraint(equalTo: appNameLabel.trailingAnchor, constant: 12),
    titleLabel.centerYAnchor.constraint(equalTo: topBarCard.centerYAnchor),
    
    // Country selector
    countryLabel.trailingAnchor.constraint(equalTo: topBarCard.trailingAnchor, constant: -16),
    countryLabel.centerYAnchor.constraint(equalTo: topBarCard.centerYAnchor),
    countryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
    countryLabel.heightAnchor.constraint(equalToConstant: 32),
])

// Đặt auto layout cho bottom bar
NSLayoutConstraint.activate([
    bottomBarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    bottomBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
    bottomBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
    bottomBarContainer.heightAnchor.constraint(equalToConstant: 60),
    
    // Card bên trong
    bottomBarCard.topAnchor.constraint(equalTo: bottomBarContainer.topAnchor),
    bottomBarCard.leadingAnchor.constraint(equalTo: bottomBarContainer.leadingAnchor),
    bottomBarCard.trailingAnchor.constraint(equalTo: bottomBarContainer.trailingAnchor),
    bottomBarCard.bottomAnchor.constraint(equalTo: bottomBarContainer.bottomAnchor),
    
    // Tab bar
    tabBar.topAnchor.constraint(equalTo: bottomBarCard.topAnchor),
    tabBar.leadingAnchor.constraint(equalTo: bottomBarCard.leadingAnchor),
    tabBar.trailingAnchor.constraint(equalTo: bottomBarCard.trailingAnchor),
    tabBar.bottomAnchor.constraint(equalTo: bottomBarCard.bottomAnchor),
    
    // Container view cho content
    containerView.topAnchor.constraint(equalTo: topBarContainer.bottomAnchor, constant: 8),
    containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    containerView.bottomAnchor.constraint(equalTo: bottomBarContainer.topAnchor, constant: -8)
])
```

## 4. Triển khai với UIKit và SwiftUI

### UIKit (Tích hợp trong MainViewController):

```swift
class MainViewController: UIViewController, UITabBarDelegate {
    // Properties
    private var containerView: UIView!
    private var topBarCard: UIView!
    private var bottomBarCard: UIView!
    private var titleLabel: UILabel!
    private var countryLabel: UILabel!
    private var tabBar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Đọc thông tin quốc gia từ UserDefaults
        let country = UserDefaults.standard.string(forKey: "country") ?? "vn"
        
        setupUI(country: country)
        setupConstraints()
        
        // Khởi tạo SinglePointViewController là màn hình mặc định
        let initialVC = SinglePointViewController()
        showViewController(initialVC)
    }
    
    private func setupUI(country: String) {
        // Tạo các thành phần UI theo mô tả ở trên
        // ...
    }
    
    private func setupConstraints() {
        // Thiết lập các constraints như mô tả ở trên
        // ...
    }
    
    // MARK: - Tab Bar Delegate
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        // Xử lý sự kiện chọn tab như mô tả ở trên
        // ...
    }
    
    // MARK: - Country Selector
    @objc func showCountrySelector() {
        // Hiển thị ActionSheet như mô tả ở trên
        // ...
    }
    
    private func changeCountry(to code: String, name: String) {
        // Cập nhật quốc gia như mô tả ở trên
        // ...
    }
    
    private func showViewController(_ viewController: UIViewController) {
        // Xử lý thay đổi view controller như mô tả ở trên
        // ...
    }
    
    private func updateTitle(_ title: String) {
        titleLabel.text = title
    }
}
```

### SwiftUI (Phiên bản thay thế):

```swift
struct MainView: View {
    @State private var selectedTab = 0
    @State private var screenTitle = "Single Point"
    @State private var country = "vn"
    @State private var countryName = "Việt Nam"
    @State private var showingCountryPicker = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    HStack(spacing: 8) {
                        Image("app_logo")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                        
                        Text("TrackAsia")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(screenTitle)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingCountryPicker = true
                    }) {
                        Text(countryName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color("colorBlue"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color("colorBlue"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Content
                TabView(selection: $selectedTab) {
                    SinglePointView()
                        .tag(0)
                        .onAppear { screenTitle = "Single Point" }
                    
                    MultiPointView()
                        .tag(1)
                        .onAppear { screenTitle = "Multi-Point" }
                    
                    ClusterView()
                        .tag(2)
                        .onAppear { screenTitle = "Clusters" }
                    
                    AnimationView()
                        .tag(3)
                        .onAppear { screenTitle = "Animation" }
                    
                    FeaturesView()
                        .tag(4)
                        .onAppear { screenTitle = "Features" }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Bottom Tab Bar
                HStack {
                    TabButtonView(imageName: "ic_map_single", title: "Single Point", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButtonView(imageName: "ic_map_multi", title: "Multi-Point", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButtonView(imageName: "ic_map_cluster", title: "Clusters", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    
                    TabButtonView(imageName: "ic_map_animation", title: "Animation", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                    
                    TabButtonView(imageName: "ic_feature", title: "Features", isSelected: selectedTab == 4) {
                        selectedTab = 4
                    }
                }
                .padding(.vertical, 8)
                .background(Color("colorBlue"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: -2)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .actionSheet(isPresented: $showingCountryPicker) {
            ActionSheet(title: Text("Chọn quốc gia"), buttons: [
                .default(Text("Việt Nam")) { 
                    country = "vn"
                    countryName = "Việt Nam"
                },
                .default(Text("Singapore")) { 
                    country = "sg"
                    countryName = "Singapore"
                },
                .default(Text("Thailand")) { 
                    country = "th"
                    countryName = "Thailand"
                },
                .cancel()
            ])
        }
        .onAppear {
            // Khởi tạo từ UserDefaults nếu cần
            if let savedCountry = UserDefaults.standard.string(forKey: "country") {
                country = savedCountry
                countryName = getCountryName(from: savedCountry)
            }
        }
    }
    
    private func getCountryName(from code: String) -> String {
        switch code {
        case "vn": return "Việt Nam"
        case "sg": return "Singapore" 
        case "th": return "Thailand"
        default: return "Việt Nam"
        }
    }
}

struct TabButtonView: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
```

## 5. Lưu ý khi triển khai:

1. **Đảm bảo assets và colors:**
   - Tạo các colors trong Assets.xcassets cho các màu sắc chung (colorBlue, colorWhite, colorGreen, v.v.)
   - Tạo các icon cần thiết cho tabbar (ic_map_single, ic_map_multi, ic_map_cluster, ic_map_animation, ic_feature)

2. **Tính năng chọn quốc gia:**
   - Sử dụng UserDefaults để lưu thông tin quốc gia được chọn
   - Cần cập nhật liệu quốc gia khi thay đổi các style maps

3. **Phần Content:**
   - Content container nằm giữa top bar và bottom bar
   - Mỗi tab sẽ load một view controller con tương ứng
   - Các view controller con này sẽ cần tham chiếu đến quốc gia hiện tại để load maps tương ứng

4. **Phong cách thiết kế:**
   - Bo tròn các corners và tạo shadow để có hiệu ứng Card giống Android
   - Để tạo hiệu ứng elevation, sử dụng shadows với các thông số tương ứng
   - Đảm bảo màu sắc và font chữ nhất quán với phiên bản Android
