//
//  Toast.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import Foundation

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let duration: Double
} 