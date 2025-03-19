//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia

struct MapWayPointView: View {
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                MapViewController(viewModel: viewModel)
                    .onAppear {
                        viewModel.prepareForModeChange()
                        viewModel.mode = .wayPoint
                        viewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
                    }
                    .onDisappear {
                        viewModel.clearMap()
                    }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.clearMap()
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .padding(10)
                        }
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                        .padding(16)
                        .padding(.bottom, 26)
                    }
                }
            }
            .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                print("MapWayPointView Selected Country changed to: \(selectedCountry)")
                viewModel.updateMap(selectedCountry: selectedCountry)
            }
        }
    }
}
