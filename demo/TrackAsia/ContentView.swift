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
                MapSinglePointView()
                    .tabItem {
                        Image(systemName: getTabImageName(0))
                        Text(tabTitles[0])
                    }
                    .tag(0)
                
                MapWayPointView()
                    .tabItem {
                        Image(systemName: getTabImageName(1))
                        Text(tabTitles[1])
                    }
                    .tag(1)
                
                MapClutterView()
                    .tabItem {
                        Image(systemName: getTabImageName(2))
                        Text(tabTitles[2])
                    }
                    .tag(2)
                
                MapAnimationView()
                    .tabItem {
                        Image(systemName: getTabImageName(3))
                        Text(tabTitles[3])
                    }
                    .tag(3)
                
                MapFeatureView()
                    .tabItem {
                        Image(systemName: getTabImageName(4))
                        Text(tabTitles[4])
                    }
                    .tag(4)
            }
            .onAppear {
                if let storedCountry = UserDefaults.standard.string(forKey: "selectedCountry") {
                    countrySettings.selectedCountry = storedCountry
                }
            }
        }
        .environmentObject(countrySettings)
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

