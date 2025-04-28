//
//  TopBarView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI

struct TopBarView: View {
    @Binding var screenTitle: String
    @Binding var selectedCountry: String
    var countries: [String: String]
    var onCountrySelected: (String) -> Void
    
    @State private var showCountrySelector = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("colorBlue"))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            HStack {
                // Logo and app name
                HStack(spacing: 8) {
                    Image("app_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                    
                    Text("TrackAsia")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Screen title
                Text(screenTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .onChange(of: screenTitle) { newValue in
                        print("🏷️ Title changed to: \(newValue)")
                    }
                
                Spacer()
                
                // Country selector
                Button(action: {
                    showCountrySelector = true
                }) {
                    Text(MapUtils.getNameContry(idCountry: selectedCountry))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("colorBlue"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                        )
                }
                .actionSheet(isPresented: $showCountrySelector) {
                    var buttons: [ActionSheet.Button] = []
                    
                    for (code, name) in countries {
                        buttons.append(.default(Text(name)) {
                            onCountrySelected(code)
                        })
                    }
                    
                    buttons.append(.cancel())
                    
                    return ActionSheet(title: Text("Chọn quốc gia"), buttons: buttons)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 56)
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .onAppear {
            print("🏷️ TopBarView appeared with title: \(screenTitle)")
        }
    }
} 