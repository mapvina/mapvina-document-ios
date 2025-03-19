//
//  MenuPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//
import SwiftUI
import TrackAsia
import Alamofire
import Combine

struct AddressSearchView: View {
    @Binding var searchText: String
    @State private var isListVisible = false
    @State private var selectedAddress: String?
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @ObservedObject var addressRepository = AddressRepository()
    @StateObject private var markerManager = MarkerManager()
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack {
            ZStack(alignment: .trailing) {
                TextField("Nhập địa chỉ", text: $searchText, onEditingChanged: { isEditing in
                    isListVisible = isEditing
                }, onCommit: {
                    isListVisible = false
                    hideKeyboard()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .onChange(of: searchText) { newValue in
                    addressRepository.fetchAddresses(with: newValue)
                }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        hideKeyboard()
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }
            }
            if isListVisible && !searchText.isEmpty {
                VStack {
                    List(addressRepository.addresses, id: \.self.label) { suggestion in
                        Text(suggestion.label)
                            .onTapGesture {
                                searchText = suggestion.label
                                isListVisible = false
                                hideKeyboard()
                                selectedAddress = suggestion.label
                                if(suggestion.coordinates.isEmpty == false){
                                    let latitude: Double = suggestion.coordinates[1]
                                    let longitude: Double = suggestion.coordinates[0]
                                    selectedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    viewModel.addMarker(at: selectedCoordinate!, title: suggestion.label)
                                    viewModel.moveCamera(to: selectedCoordinate!, zoom: 14)
                                }
                            }
                    }
                    .listStyle(InsetListStyle())
                    .frame(height: 240)
                    .clipped()
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct MapSinglePointView: View {
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                MapViewController(viewModel: viewModel)
                    .onAppear {
                        viewModel.prepareForModeChange()
                        viewModel.mode = .singlePoint
                        viewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
                    }
                    .onDisappear {
                        viewModel.clearMap()
                    }
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    AddressSearchView(searchText: $searchText, viewModel: viewModel)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Spacer()
                        
                        Button(action: {
                            hideKeyboard()
                        }) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundColor(.blue)
                                .padding(10)
                        }
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                        
                        Button(action: {
                            viewModel.centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .padding(10)
                        }
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                    }
                    .padding(16)
                    .padding(.bottom, 26)
                }
            }
            .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                print("MapSinglePointView Selected Country changed to: \(selectedCountry)")
                viewModel.updateMap(selectedCountry: selectedCountry)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
