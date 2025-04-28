//
//  DataRepository.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 19/12/2023.
//

import Foundation
import SwiftUI
import TrackAsia
import MapboxDirections
import MapboxCoreNavigation
import CoreLocation
// import Alamofire  // Commented due to dependency issues
import Combine
import Alamofire

// MARK: - Error Types Extension
extension NetworkError {
    // Add new cases for our needs
    static let invalidURL = NetworkError.requestFailed
    static let noCountrySelected = NetworkError.requestFailed
    static let parsingFailed = NetworkError.requestFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidData: return "Dữ liệu không hợp lệ"
        case .requestFailed: return "Lỗi kết nối"
        }
    }
}

// MARK: - Notification Control
// Đặt biến kiểm soát thông báo ở cấp độ global để các repository có thể truy cập
private var lastToastTimestamp: Date?
private let minimumToastInterval: TimeInterval = 1.0

// MARK: - API Service
class APIService {
    static let shared = APIService()
    
    private init() {}
    
    // Tạo URLRequest chuẩn
    func createRequest(for url: URL, timeoutInterval: TimeInterval = 15.0) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutInterval
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        return request
    }
    
    // Helper để lấy URL cơ bản từ quốc gia đã chọn
    func getBaseURL() -> Result<String, NetworkError> {
        guard let selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") else {
            return .failure(.noCountrySelected)
        }
        return .success(MapUtils.urlDomain(idCountry: selectedCountry))
    }
    
    // Tạo URL cho geocoding ngược từ tọa độ
    func createReverseGeocodingURL(lat: String, lng: String) -> Result<URL, NetworkError> {
        return getBaseURL().flatMap { baseURL in
            let urlString = "\(baseURL)/api/v1/reverse?lang=vi&point.lon=\(lng)&point.lat=\(lat)&key=public_key"
            guard let url = URL(string: urlString) else {
                return .failure(.invalidURL)
            }
            return .success(url)
        }
    }
    
    // Tạo URL cho tìm kiếm tự động hoàn thành
    func createAutocompleteURL(text: String) -> Result<URL, NetworkError> {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(.invalidURL)
        }
        
        return getBaseURL().flatMap { baseURL in
            let urlString = "\(baseURL)/api/v1/autocomplete?lang=vi&text=\(encodedText)&key=public_key"
            guard let url = URL(string: urlString) else {
                return .failure(.invalidURL)
            }
            return .success(url)
        }
    }
}

// MARK: - Address Formatting Utilities
struct AddressFormatter {
    // Định dạng tọa độ thành chuỗi
    static func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
    
    // Tạo địa chỉ mặc định từ tọa độ
    static func createDefaultAddressModel(coordinate: CLLocationCoordinate2D) -> AddressModel {
        let formattedLat = String(format: "%.6f", coordinate.latitude)
        let formattedLng = String(format: "%.6f", coordinate.longitude)
        
        return AddressModel(
            id: "default",
            name: "Vị trí đã chọn",
            label: "Tọa độ \(formattedLat), \(formattedLng)",
            coordinates: [coordinate.longitude, coordinate.latitude]
        )
    }
    
    // Xác định label tốt nhất cho địa chỉ
    static func determineBestLabel(label: String, name: String, coordinate: CLLocationCoordinate2D) -> String {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedLabel.isEmpty {
            return trimmedLabel
        } else if !trimmedName.isEmpty {
            return trimmedName
        } else {
            return "Vị trí \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
        }
    }
    
    // Convert từ string coordinate thành CLLocationCoordinate2D
    static func makeCoordinate(lat: String, lng: String) -> CLLocationCoordinate2D {
        let latitude = Double(lat) ?? 0
        let longitude = Double(lng) ?? 0
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Xử lý features từ response thành AddressModel - chung cho các kiểu response
    static func processFeatures<T: GeoFeature>(
        _ features: [T], 
        coordinate: CLLocationCoordinate2D,
        createDefault: Bool = true
    ) -> [AddressModel] {
        guard !features.isEmpty else {
            return createDefault ? [createDefaultAddressModel(coordinate: coordinate)] : []
        }
        
        return features.map { feature in
            // Lấy properties từ feature
            let props = feature.geoProperties
            
            // Xác định label tốt nhất
            let finalLabel = determineBestLabel(
                label: props.label,
                name: props.name,
                coordinate: coordinate
            )
            
            return AddressModel(
                id: props.id,
                name: props.name,
                label: finalLabel,
                coordinates: feature.geoGeometry.coordinates
            )
        }
    }
    
    // Gửi thông báo cập nhật địa chỉ
    static func notifyAddressUpdate(coordinate: CLLocationCoordinate2D, addresses: [AddressModel]) {
        var processedAddresses = addresses
        
        // Kiểm tra và xử lý địa chỉ trước khi gửi thông báo
        if let firstAddress = addresses.first {
            // Xử lý trường hợp label trống
            if firstAddress.label.isEmpty {
                let updatedAddress: AddressModel
                
                if !firstAddress.name.isEmpty {
                    updatedAddress = AddressModel(
                        id: firstAddress.id,
                        name: firstAddress.name,
                        label: firstAddress.name,
                        coordinates: firstAddress.coordinates
                    )
                } else {
                    let defaultLabel = "Vị trí \(String(format: "%.6f", coordinate.latitude)), \(String(format: "%.6f", coordinate.longitude))"
                    updatedAddress = AddressModel(
                        id: firstAddress.id,
                        name: defaultLabel,
                        label: defaultLabel,
                        coordinates: firstAddress.coordinates
                    )
                }
                
                processedAddresses = [updatedAddress]
            }
        }
        
        // Tạo và gửi thông báo
        let userInfo: [String: Any] = [
            "addresses": processedAddresses,
            "addressModels": processedAddresses, // Thêm key mới để đảm bảo tương thích
            "coordinate": coordinate,
            "timestamp": Date()
        ]
        
        // Đặt trong DispatchQueue.main để đảm bảo thông báo luôn được gửi trên main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("AddressUpdated"),
                object: nil,
                userInfo: userInfo
            )
        }
    }
}

// MARK: - GeoFeature Protocol để thống nhất xử lý Feature
protocol GeoFeature {
    associatedtype PropertiesType: GeoProperties
    var geoProperties: PropertiesType { get }
    var geoGeometry: GeometryObject { get }
}

protocol GeoProperties {
    var id: String { get }
    var name: String { get }
    var label: String { get }
}

// MARK: - Định nghĩa GeometryObject
struct GeometryObject {
    let coordinates: [Double]
    let type: String
    
    // Khởi tạo từ kiểu AddressResponse.Geometry
    init(from geometry: AddressResponse.Geometry) {
        self.coordinates = geometry.coordinates
        self.type = geometry.type
    }
    
    // Khởi tạo từ kiểu GeocodingResponse.Geometry
    init(from geometry: GeocodingResponse.Geometry) {
        self.coordinates = geometry.coordinates
        self.type = geometry.type
    }
}

// MARK: - Extension cho AddressResponse.Feature
extension AddressResponse.Feature: GeoFeature {
    typealias PropertiesType = AddressResponse.Properties
    
    var geoProperties: AddressResponse.Properties {
        return self.properties
    }
    
    var geoGeometry: GeometryObject {
        return GeometryObject(from: self.geometry)
    }
}

// MARK: - Extension cho GeocodingResponse.Feature
extension GeocodingResponse.Feature: GeoFeature {
    typealias PropertiesType = GeocodingResponse.Properties
    
    var geoProperties: GeocodingResponse.Properties {
        return self.properties
    }
    
    var geoGeometry: GeometryObject {
        return GeometryObject(from: self.geometry)
    }
}

// MARK: - Extension cho AddressResponse.Properties
extension AddressResponse.Properties: GeoProperties {}

// MARK: - Extension cho GeocodingResponse.Properties
extension GeocodingResponse.Properties: GeoProperties {}

// MARK: - Repository Classes
class AddressRepository: ObservableObject {
    @Published var addresses: [AddressModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private var cancellable: AnyCancellable?
    
    func fetchAddresses(with text: String) {
        // Validate input
        guard text.count >= 2 else {
            self.addresses = []
            return
        }
        
        // Tạo URL và thực hiện request
        let urlResult = APIService.shared.createAutocompleteURL(text: text)
        switch urlResult {
        case .failure(let error):
            self.errorMessage = error.localizedDescription
        case .success(let url):
            performRequest(url: url)
        }
    }
    
    private func performRequest(url: URL) {
        self.isLoading = true
        self.errorMessage = nil
        
        let request = APIService.shared.createRequest(for: url)
        
        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: AddressResponse.self, decoder: JSONDecoder())
            .map { response in
                response.features.map { feature in
                    // Use the direct feature.properties here since we're not using it as GeoFeature
                    return AddressModel(
                        id: feature.properties.id,
                        name: feature.properties.name,
                        label: feature.properties.label,
                        coordinates: feature.geometry.coordinates
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.errorMessage = "Không thể tìm kiếm: \(error.localizedDescription)"
                    self.addresses = []
                }
            }, receiveValue: { [weak self] addresses in
                guard let self = self else { return }
                self.addresses = addresses
                self.isLoading = false
            })
    }
}

class GeocodingRepository: ObservableObject {
    @Published var addresses: [AddressModel] = []
    private var isRequestInProgress = false
    private var cancellables = Set<AnyCancellable>()
    
    // Giữ tham chiếu static để tránh bị giải phóng sớm
    private static var activeInstances = [GeocodingRepository]()
    
    // MARK: - API Methods
    
    /// Lấy địa chỉ từ tọa độ
    func fetchGeocoding(lat: String, lng: String) {
        guard !isRequestInProgress else { return }
        isRequestInProgress = true
        
        // Thêm self vào danh sách active để tránh bị giải phóng sớm
        Self.activeInstances.append(self)
        
        let coordinate = CLLocationCoordinate2D(latitude: Double(lat) ?? 0, longitude: Double(lng) ?? 0)
        
        // Tạo URL cho yêu cầu ngược
        let urlResult = APIService.shared.createReverseGeocodingURL(lat: lat, lng: lng)
        
        switch urlResult {
        case .failure(_):
            handleFailure(coordinate: coordinate)
            return
        case .success(let url):
            // Headers chuẩn
            let headers: HTTPHeaders = [
                "Accept": "application/json",
                "User-Agent": "TrackAsiaDemo/1.0"
            ]
            
            // Thực hiện request
            AF.request(url, method: .get, headers: headers)
                .validate()
                .responseData { [weak self] response in
                    guard let self = self else {
                        // Xử lý ngay cả khi self bị giải phóng
                        if let data = response.data, !data.isEmpty {
                            Self.handleStaticResponse(data: data, coordinate: coordinate)
                        } else {
                            Self.notifyDefaultAddress(coordinate: coordinate)
                        }
                        
                        // Xóa khỏi danh sách active
                        if let strongSelf = self {
                            Self.removeFromActiveInstances(repository: strongSelf)
                        }
                        return
                    }
                    
                    // Đảm bảo reset trạng thái khi kết thúc
                    defer {
                        self.isRequestInProgress = false
                        Self.removeFromActiveInstances(repository: self)
                    }
                    
                    // Xử lý lỗi HTTP
                    if let statusCode = response.response?.statusCode, (statusCode < 200 || statusCode >= 300) {
                        self.handleFailure(coordinate: coordinate)
                        return
                    }
                    
                    // Xử lý lỗi Network
                    if response.error != nil || response.data == nil || response.data!.isEmpty {
                        self.handleFailure(coordinate: coordinate)
                        return
                    }
                    
                    // Parse dữ liệu
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(GeocodingResponse.self, from: response.data!)
                        
                        // Tạo địa chỉ từ kết quả
                        let addressModels = AddressFormatter.processFeatures(response.features, coordinate: coordinate)
                        
                        DispatchQueue.main.async {
                            // Cập nhật state
                            self.addresses = addressModels
                            
                            // Gửi thông báo với địa chỉ đã tìm thấy
                            AddressFormatter.notifyAddressUpdate(coordinate: coordinate, addresses: addressModels)
                        }
                    } catch {
                        self.handleFailure(coordinate: coordinate)
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Xử lý response khi self đã bị giải phóng
    private static func handleStaticResponse(data: Data, coordinate: CLLocationCoordinate2D) {
        do {
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            let addressModels = AddressFormatter.processFeatures(response.features, coordinate: coordinate)
            AddressFormatter.notifyAddressUpdate(coordinate: coordinate, addresses: addressModels)
        } catch {
            notifyDefaultAddress(coordinate: coordinate)
        }
    }
    
    /// Xử lý tạo địa chỉ mặc định khi có lỗi (static)
    private static func notifyDefaultAddress(coordinate: CLLocationCoordinate2D) {
        let defaultAddress = AddressFormatter.createDefaultAddressModel(coordinate: coordinate)
        AddressFormatter.notifyAddressUpdate(coordinate: coordinate, addresses: [defaultAddress])
    }
    
    /// Xử lý khi có lỗi, tạo địa chỉ mặc định
    private func handleFailure(coordinate: CLLocationCoordinate2D) {
        let defaultAddress = AddressFormatter.createDefaultAddressModel(coordinate: coordinate)
        self.addresses = [defaultAddress]
        AddressFormatter.notifyAddressUpdate(coordinate: coordinate, addresses: [defaultAddress])
        isRequestInProgress = false
    }
    
    /// Quản lý danh sách active instances
    private static func removeFromActiveInstances(repository: GeocodingRepository) {
        if let index = activeInstances.firstIndex(where: { $0 === repository }) {
            activeInstances.remove(at: index)
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
}

class PetLocationRepository: ObservableObject {
    @Published var clusters: [AddressModel] = []
    private var cancellable: AnyCancellable?
    
    func fetchData() {
        guard let url = URL(string: "https://panel.hainong.vn/api/v2/diagnostics/pets_map") else {
            return
        }
        
        cancellable = AF.request(url)
            .publishData()
            .tryMap { dataResponse in
                guard let data = dataResponse.data else {
                    throw NetworkError.invalidData
                }
                return try JSONDecoder().decode(AddressResponse.self, from: data)
            }
            .map { response in
                response.features.map { feature in
                    // Use the direct feature.properties here since we're not using it as GeoFeature
                    return AddressModel(
                        id: feature.properties.id,
                        name: feature.properties.name,
                        label: feature.properties.label,
                        coordinates: feature.geometry.coordinates
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Network request failed with error: \(error)")
                }
            }, receiveValue: { [weak self] addresses in
                self?.clusters = addresses
            })
    }
}



