//
//  MapAnimationView.swift
//  TrackAsia
//
//  Created by CodeRefactor on 29/04/2024.
//

import SwiftUI
import CoreLocation
import TrackAsia
import Alamofire

struct MapAnimationView: View {
   @StateObject private var viewModel: MapViewModel
   
   init(mapViewModel: MapViewModel) {
      _viewModel = StateObject(wrappedValue: mapViewModel)
   }
    
   var body: some View {
       VStack {
           Spacer()
           
           HStack {
               Button(action: {
                   toggleAnimation()
               }) {
                   Image(systemName: viewModel.isAnimating ? "pause.fill" : "play.fill")
                       .foregroundColor(.blue)
                       .padding(12)
                       .background(Circle().fill(Color.white))
                       .shadow(radius: 2)
               }
               .padding(.leading, 16)
               .padding(.bottom, 16)
               
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
   }
   
   private func toggleAnimation() {
       if viewModel.isAnimating {
           viewModel.stopAnimatingPolyline()
       } else {
           viewModel.startAnimatingPolyline()
       }
   }
}

#Preview {
   MapAnimationView(mapViewModel: MapViewModel())
} 
