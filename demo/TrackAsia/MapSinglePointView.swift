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
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @ObservedObject var addressRepository = AddressRepository()
    @StateObject private var markerManager = MarkerManager()
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        VStack {
            ZStack(alignment: .trailing){
                TextField("Nhập địa chỉ", text: $searchText, onEditingChanged: { isEditing in
                    isListVisible = isEditing
                }, onCommit: {
                    isListVisible = false
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .focused($isTextFieldFocused)
                .onChange(of: searchText) { newValue in
                    addressRepository.fetchAddresses(with: newValue)
                }
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            isListVisible = true
                        }
                )
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(.secondary).onTapGesture {
                                isListVisible = true
                                searchText = ""
                            }
                    }.padding(.top, 16).padding(.horizontal, 20)
                        .onTapGesture {
                            isListVisible = true
                            searchText = ""
                        }
                }
            }
            if isListVisible && !searchText.isEmpty {
                VStack {
                    List(addressRepository.addresses, id: \.self.label) { suggestion in
                        Text(suggestion.label)
                            .onTapGesture {
                                searchText = suggestion.label
                                isListVisible = false
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
                    .onTapGesture {
                        isListVisible = false
                    }
                }
            }
        }
    }
    
}


struct MapSinglePointView: View {
    @EnvironmentObject private var countrySettings: CountrySettings
    @StateObject private var viewModel = MapViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                MapViewController(viewModel: viewModel)
                    .onAppear {
                        viewModel.prepareForModeChange()
                        viewModel.mode = .singlePoint
                        viewModel.updateMap(selectedCountry: countrySettings.selectedCountry)
                    }
                    .onDisappear {
                        viewModel.clearMap()
                    }
                
                VStack(spacing: 0) {
                    AddressSearchView(searchText: $searchText, viewModel: viewModel)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
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
                        .padding(16)
                        .padding(.bottom, 26)
                    }
                }
            }
            .onChange(of: countrySettings.selectedCountry) { selectedCountry in
                print("MapSinglePointView Selected Country changed to: \(selectedCountry)")
                viewModel.updateMap(selectedCountry: selectedCountry)
            }
            .navigationTitle("Single Point")
        }
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
