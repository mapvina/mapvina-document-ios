//
//  ContentView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 13/12/2023.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var countrySettings = CountrySettings()
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showDropdown = false
    @State private var currentPage = 0
    @State private var countries: [String: String] = [
        "vn": "Vietnam",
        "sg": "Singapore",
        "th": "Thailand",
    ]
    let tabTitles = ["Single Point", "Way Point", "Cluster", "Animation", "Feature"]
    
    var body: some View {
        VStack {
            // Menu bar
            HStack {
                Text(tabTitles[currentPage])
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                Button(action: {
                    showDropdown.toggle()
                }) {
                    Label(MapUtils.getNameContry(idCountry: countrySettings.selectedCountry), systemImage: "globe")
                }
                .popover(isPresented: $showDropdown) {
                    List(countries.keys.sorted(), id: \.self) { key in
                        Button(action: {
                            countrySettings.selectedCountry = key
                            UserDefaults.standard.set(key, forKey: "selectedCountry")
                            mapViewModel.updateMap(selectedCountry: key)
                            showDropdown.toggle()
                        }) {
                            Text(countries[key] ?? "Unknown")
                        }
                    }
                }
                Spacer()
            }
            .padding()
            
            TabView(selection: $currentPage) {
                ForEach(0..<tabTitles.count, id: \.self) { index in
                    MapViewController(viewModel: mapViewModel)
                        .onAppear {
                            mapViewModel.mode = getMapMode(index)
                        }
                        .tabItem {
                            Image(systemName: getTabImageName(index))
                            Text(tabTitles[index])
                        }
                        .tag(index)
                }
            }
            .onAppear {
                if let storedCountry = UserDefaults.standard.string(forKey: "selectedCountry") {
                    countrySettings.selectedCountry = storedCountry
                    mapViewModel.updateMap(selectedCountry: storedCountry)
                }
            }
        }
        .environmentObject(countrySettings)
    }
    
    func getMapMode(_ index: Int) -> MapViewMode {
        switch index {
        case 0: return .singlePoint
        case 1: return .wayPoint
        case 2: return .cluster
        case 3: return .animation
        case 4: return .feature
        default: return .singlePoint
        }
    }
    
    func getTabImageName(_ index: Int) -> String {
        switch index {
        case 0: return "location.fill"
        case 1: return "map.fill"
        case 2: return "square.fill"
        case 3: return "arrow.triangle.turn.up.right.circle.fill"
        case 4: return "star.fill"
        default: return ""
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}

