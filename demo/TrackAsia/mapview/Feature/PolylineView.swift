//
//  PolylineView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 26/12/2023.
//

import Foundation
import SwiftUI
import TrackAsia
import MapboxNavigation


func drawPolyline(_ mapView: MLNMapView) {
    guard let url = Bundle.main.url(forResource: "iOSLineGeoJSON", withExtension: "geojson"),
          let jsonData = try? Data(contentsOf: url),
          let style = mapView.style,
          let shapeFromGeoJSON = try? MLNShape(data: jsonData, encoding: String.Encoding.utf8.rawValue) else {
        preconditionFailure("Failed to parse GeoJSON file")
    }

    let sourceIdentifier = "polyline"
    if let existingSource = style.source(withIdentifier: sourceIdentifier) as? MLNShapeSource {
        existingSource.shape = shapeFromGeoJSON
    } else {
        let source = MLNShapeSource(identifier: sourceIdentifier, shape: shapeFromGeoJSON, options: [MLNShapeSourceOption.lineDistanceMetrics: true])
        style.addSource(source)
        let layer = MLNLineStyleLayer(identifier: sourceIdentifier, source: source)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        let stops = [0: UIColor.blue,
                     0.1: UIColor.purple,
                     0.3: UIColor.cyan,
                     0.5: UIColor.green,
                     0.7: UIColor.yellow,
                     1: UIColor.red]
        layer.lineGradient = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", stops)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                       [14: 10, 18: 20])
        style.addLayer(layer)
    }
}

