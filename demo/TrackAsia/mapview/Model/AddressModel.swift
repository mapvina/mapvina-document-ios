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
    }
}
