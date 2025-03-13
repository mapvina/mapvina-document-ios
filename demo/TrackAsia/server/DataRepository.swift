//
//  DataRepository.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 19/12/2023.
//

import Foundation
import Alamofire
import Combine

class AddressRepository: ObservableObject {
    @Published var addresses: [AddressModel] = []
    private var cancellable: AnyCancellable?
    
    func fetchAddresses(with text: String) {
        guard let selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") else {
            return
        }
        let domainURL = MapUtils.urlDomain(idCountry: selectedCountry)
        guard let url = URL(string: "\(domainURL)/api/v1/autocomplete?lang=vi&text=\(text)") else {
            return
        }
        
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AddressResponse.self, decoder: JSONDecoder())
            .map { response in
                print("API Response: \(response)")
                return response.features.map { feature in
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
                switch completion {
                case .failure(let error):
                    // Handle other failure cases if needed
                    print("Network request failed with error: \(error)")
                    // Cập nhật addresses ngay cả khi có lỗi
                    self?.addresses = []
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] addresses in
                
                self?.addresses = addresses
                
            })
    }
}

class GeocodingRepository: ObservableObject {
    @Published var addresses: [AddressModel] = []
    private var cancellable: AnyCancellable?
    
    func fetchGeocoding(lat: String, lng: String) {
        guard let selectedCountry = UserDefaults.standard.string(forKey: "selectedCountry") else {
            return
        }
        let domainURL = MapUtils.urlDomain(idCountry: selectedCountry)
        guard let url = URL(string: "\(domainURL)/api/v1/reverse?lang=vi&point.lon=\(lng)&point.lat=\(lat)") else {
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
                print("API Response: \(response)")
                return response.features.compactMap { feature in
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
                switch completion {
                case .failure(let error):
                    // Handle other failure cases if needed
                    print("Network request failed with error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] addresses in
                
                self?.addresses = addresses
            })
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
                print("API Response: \(response)")
                return response.features.compactMap { feature in
                    return AddressModel(
                        id: feature.properties.id,
                        name: feature.properties.name,
                        label: feature.properties.label,
                        coordinates: feature.geometry.coordinates
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    // Handle other failure cases if needed
                    print("Network request failed with error: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] addresses in
                self?.clusters = addresses
            })
    }
}

