//
//  MapCompareView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia

struct MapCompareView: View {
    @StateObject private var viewModel: MapViewModel
    
    init(mapViewModel: MapViewModel) {
        _viewModel = StateObject(wrappedValue: mapViewModel)
    }
    
    var body: some View {
        VStack {
            Text("Map Comparison Mode")
                .font(.headline)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.8)))
                .shadow(radius: 2)
                .padding(.top, 16)
            
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
//            viewModel.setupCompareView()
        }
        .onDisappear {
//            viewModel.hideCompareView()
        }
    }
}

#Preview {
    MapCompareView(mapViewModel: MapViewModel())
} 
