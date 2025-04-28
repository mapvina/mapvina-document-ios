//
//  SearchAddressModel.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import Foundation

struct SearchAddressModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let label: String
    let coordinates: [Double]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchAddressModel, rhs: SearchAddressModel) -> Bool {
        lhs.id == rhs.id
    }
} 