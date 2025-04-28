//
//  BottomBarView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI

struct BottomBarView: View {
    @Binding var selectedTab: Int
    
    let tabTitles = [
        "Single Point",
        "Multi-Point",
        "Clusters",
        "Animation",
        "Features"
    ]
    
    let tabIcons = [
        "ic_map_single",
        "ic_map_multi",
        "ic_map_cluster",
        "ic_map_animation",
        "ic_feature"
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("colorBlue"))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: -2)
            
            HStack(spacing: 0) {
                ForEach(0..<tabTitles.count, id: \.self) { index in
                    TabButtonView(
                        imageName: tabIcons[index],
                        title: tabTitles[index],
                        isSelected: selectedTab == index
                    ) {
                        print("🔘 Tab button tapped: \(tabTitles[index]) (index: \(index))")
                        if selectedTab != index {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 60)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

struct TabButtonView: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
} 