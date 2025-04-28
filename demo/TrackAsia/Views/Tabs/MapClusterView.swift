//
//  MapClusterView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia

struct MapClusterView: View {
    @StateObject private var viewModel: MapViewModel
    @State private var clusterViewInitialized = false
    // Giữ strong reference đến ClusterView để tránh bị giải phóng bởi ARC
    @State private var clusterView: ClusterView?
    
    init(mapViewModel: MapViewModel) {
        _viewModel = StateObject(wrappedValue: mapViewModel)
    }
    
    var body: some View {
        VStack {
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
            setupClusterView()
        }
        .onDisappear {
            // Khi view biến mất, thiết lập lại delegate gốc
            if let clusterView = clusterView {
                print("🧹 Cleaning up ClusterView resources")
                clusterView.cleanup()
                self.clusterView = nil
                clusterViewInitialized = false
            }
        }
    }
    
    private func setupClusterView() {
        print("🔄 Setting up MapClusterView")
        viewModel.updateMode(.cluster)
        
        // Use DispatchQueue to ensure the map view is fully set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create ClusterView to handle clusters
            if !clusterViewInitialized {
                print("📊 Initializing ClusterView for cluster functionality")
                
                // Lưu strong reference đến ClusterView
                if self.clusterView == nil {
                    self.clusterView = ClusterView(mapView: viewModel.mapViewManager.mapView)
                }
                
                clusterViewInitialized = true
                
                // Đảm bảo map view được refresh để hiển thị cluster
                viewModel.mapViewManager.mapView.setNeedsDisplay()
                
                print("✅ ClusterView initialization complete")
            }
        }
    }
}

#Preview {
    MapClusterView(mapViewModel: MapViewModel())
} 