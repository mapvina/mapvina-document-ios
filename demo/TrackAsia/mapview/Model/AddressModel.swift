//
//  AddressModel.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 19/12/2023.
//

import Foundation


struct AddressResponse: Decodable {
    let features: [Feature]
    
    struct Feature: Decodable {
        let type: String
        let geometry: Geometry
        let properties: Properties
    }
    
    struct Geometry: Decodable {
        let type: String
        let coordinates: [Double]
    }
    
    struct Properties: Decodable {
        let id: String
        let layer: String
        let name: String
        let label: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
            layer = try container.decodeIfPresent(String.self, forKey: .layer) ?? ""
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        }
        
        enum CodingKeys: String, CodingKey {
            case id, layer, name, label
        }
    }
    
}

// Model mới cho kết quả geocoding dựa trên cấu trúc JSON trong hình
struct GeocodingResponse: Decodable {
    let geocoding: GeocodingInfo
    let type: String
    let features: [Feature]
    let bbox: [Double]?
    
    // Thêm init để in debug khi thành công/thất bại
    init(from decoder: Decoder) throws {
        print("🔄 Đang parse GeocodingResponse...")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            geocoding = try container.decode(GeocodingInfo.self, forKey: .geocoding)
            print("✓ Decoded geocoding info")
        } catch {
            print("⚠️ Error decoding geocoding: \(error)")
            throw error
        }
        
        do {
            type = try container.decode(String.self, forKey: .type)
            print("✓ Decoded type: \(type)")
        } catch {
            print("⚠️ Error decoding type: \(error)")
            throw error
        }
        
        do {
            features = try container.decode([Feature].self, forKey: .features)
            print("✓ Decoded \(features.count) features")
        } catch {
            print("⚠️ Error decoding features: \(error)")
            throw error
        }
        
        do {
            bbox = try container.decodeIfPresent([Double].self, forKey: .bbox)
            if let bbox = bbox {
                print("✓ Decoded bbox with \(bbox.count) values")
            } else {
                print("✓ No bbox found (optional)")
            }
        } catch {
            print("⚠️ Error decoding bbox: \(error)")
            bbox = nil
        }
        
        print("✅ Successfully parsed GeocodingResponse")
    }
    
    enum CodingKeys: String, CodingKey {
        case geocoding, type, features, bbox
    }
    
    struct GeocodingInfo: Decodable {
        let timestamp: Int64
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // Thử parse Int64 cho timestamp vì JSON có thể có số lớn
            timestamp = try container.decode(Int64.self, forKey: .timestamp)
        }
        
        enum CodingKeys: String, CodingKey {
            case timestamp
        }
    }
    
    struct Feature: Decodable {
        let type: String
        let geometry: Geometry
        let properties: Properties
    }
    
    struct Geometry: Decodable {
        let type: String
        let coordinates: [Double]
    }
    
    struct Properties: Decodable {
        let id: String
        let gid: String
        let layer: String
        let country_code: String
        let name: String
        let housenumber: String?
        let street: String?
        let postalcode: String?
        let confidence: Double
        let distance: Double
        let country: String
        let country_a: String
        let region: String
        let region_a: String
        let county: String
        let locality: String
        let label: String
        let country_id: String
        let region_id: String
        let county_id: String
        let locality_id: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Sử dụng decodeIfPresent với giá trị mặc định để tránh lỗi khi thiếu trường
            id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
            gid = try container.decodeIfPresent(String.self, forKey: .gid) ?? ""
            layer = try container.decodeIfPresent(String.self, forKey: .layer) ?? ""
            country_code = try container.decodeIfPresent(String.self, forKey: .country_code) ?? ""
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
            housenumber = try container.decodeIfPresent(String.self, forKey: .housenumber)
            street = try container.decodeIfPresent(String.self, forKey: .street)
            postalcode = try container.decodeIfPresent(String.self, forKey: .postalcode)
            
            // Xử lý an toàn cho các số
            if let confidenceValue = try container.decodeIfPresent(Double.self, forKey: .confidence) {
                confidence = confidenceValue
            } else if let confidenceString = try container.decodeIfPresent(String.self, forKey: .confidence),
                      let confidenceValue = Double(confidenceString) {
                confidence = confidenceValue
            } else {
                confidence = 0.0
            }
            
            if let distanceValue = try container.decodeIfPresent(Double.self, forKey: .distance) {
                distance = distanceValue
            } else if let distanceString = try container.decodeIfPresent(String.self, forKey: .distance),
                      let distanceValue = Double(distanceString) {
                distance = distanceValue
            } else {
                distance = 0.0
            }
            
            country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
            country_a = try container.decodeIfPresent(String.self, forKey: .country_a) ?? ""
            region = try container.decodeIfPresent(String.self, forKey: .region) ?? ""
            region_a = try container.decodeIfPresent(String.self, forKey: .region_a) ?? ""
            county = try container.decodeIfPresent(String.self, forKey: .county) ?? ""
            locality = try container.decodeIfPresent(String.self, forKey: .locality) ?? ""
            label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
            country_id = try container.decodeIfPresent(String.self, forKey: .country_id) ?? ""
            region_id = try container.decodeIfPresent(String.self, forKey: .region_id) ?? ""
            county_id = try container.decodeIfPresent(String.self, forKey: .county_id) ?? ""
            locality_id = try container.decodeIfPresent(String.self, forKey: .locality_id) ?? ""
        }
        
        enum CodingKeys: String, CodingKey {
            case id, gid, layer, country_code, name, housenumber, street, postalcode
            case confidence, distance, country, country_a, region, region_a, county
            case locality, label, country_id, region_id, county_id, locality_id
        }
    }
}

struct AddressModel {
    let id: String
    let name: String
    let label: String
    let coordinates: [Double]
    
    init(id: String, name: String, label: String, coordinates: [Double]) {
        self.id = id 
        self.name = name 
        self.label = label 
        self.coordinates = coordinates 
        
        // Thêm log cho việc debug
        print("Created AddressModel: id=\(id), name='\(name)', label='\(label)'")
    }
    
    // Thêm phương thức mô tả để debug tốt hơn
    var description: String {
        return "AddressModel(id: \(id), name: \(name), label: \(label), coordinates: \(coordinates))"
    }
}
