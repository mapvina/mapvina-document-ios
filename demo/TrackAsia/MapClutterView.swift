//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia
//import MapboxAnnotationCluster
struct MapClutterView: View {
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()

    
    var body: some View {
        NavigationView {
            ZStack {
                MapViewController(viewModel: viewModel)
                    .onAppear {
                        viewModel.mode = .cluster
                    }
            }
            .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                print("MapClutterView Selected Country changed to: \(selectedCountry)")
                viewModel.updateMap(selectedCountry: selectedCountry)
            }
        }
        .environmentObject(countrySettings)
    }
}

