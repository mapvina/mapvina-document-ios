//
//  MapFeatureView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia

struct MapFeatureView: View {
    // Sử dụng StateObject thay vì ObservedObject
    @StateObject private var viewModel: MapViewModel
    
    // Local state để tracking các feature options
    @State private var showMarkers: Bool = false
    @State private var showPolyline: Bool = false
    @State private var showPolygon: Bool = false
    @State private var showHeatmap: Bool = false
    @State private var showBuildings3D: Bool = false
    
    init(mapViewModel: MapViewModel) {
        // Sử dụng StateObject.init(wrappedValue:) để khởi tạo
        _viewModel = StateObject(wrappedValue: mapViewModel)
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FeatureButton(
                        title: "Marker",
                        isActive: showMarkers,
                        action: { 
                            showMarkers.toggle()
                            viewModel.toggleFeatureOption("showMarkers") 
                        }
                    )
                    
                    FeatureButton(
                        title: "Polyline",
                        isActive: showPolyline,
                        action: { 
                            showPolyline.toggle()
                            viewModel.toggleFeatureOption("showPolyline") 
                        }
                    )
                    
                    FeatureButton(
                        title: "Polygon",
                        isActive: showPolygon,
                        action: { 
                            showPolygon.toggle()
                            viewModel.toggleFeatureOption("showPolygon") 
                        }
                    )
                    
                    FeatureButton(
                        title: "Heatmap",
                        isActive: showHeatmap,
                        action: { 
                            showHeatmap.toggle()
                            viewModel.toggleFeatureOption("showHeatmap") 
                        }
                    )
                    
                    FeatureButton(
                        title: "3D Buildings",
                        isActive: showBuildings3D,
                        action: { 
                            showBuildings3D.toggle()
                            viewModel.toggleFeatureOption("showBuildings3D") 
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(action: {
                    viewModel.centerOnUserLocation()
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .padding(12)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 2)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            // Đồng bộ local state với viewModel khi view xuất hiện
            updateLocalStateFromViewModel()
        }
    }
    
    // Phương thức để đồng bộ hóa local state với giá trị trong view model
    private func updateLocalStateFromViewModel() {
        showMarkers = viewModel.featureOptions["showMarkers"] ?? false
        showPolyline = viewModel.featureOptions["showPolyline"] ?? false
        showPolygon = viewModel.featureOptions["showPolygon"] ?? false
        showHeatmap = viewModel.featureOptions["showHeatmap"] ?? false
        showBuildings3D = viewModel.featureOptions["showBuildings3D"] ?? false
    }
}

struct FeatureButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? Color.blue : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
        }
    }
}

#Preview {
    MapFeatureView(mapViewModel: MapViewModel())
} 