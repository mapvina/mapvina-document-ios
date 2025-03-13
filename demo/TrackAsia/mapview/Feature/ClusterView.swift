//
//  ClusterView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 26/12/2023.
//

import UIKit
import TrackAsia

class ClusterView: NSObject, MLNMapViewDelegate {
    var mapView: MLNMapView?
    var icon: UIImage?

    init(mapView: MLNMapView) {
        super.init()
        self.mapView = mapView
        self.icon = UIImage(named: "cluster")
        setupCluster()
    }

    func setupCluster() {
        guard let mapView = mapView, let icon = icon else { return }

        if let existingSource = mapView.style?.source(withIdentifier: "clusteredPorts") as? MLNShapeSource {
            // Handle existing source if needed
        } else {
            let source = MLNShapeSource(identifier: "clusteredPorts",
                                        url: URL(string: "https://panel.hainong.vn/api/v2/diagnostics/pets_map.geojson")!,
                                        options: [.clustered: true, .clusterRadius: icon.size.width])
            mapView.style?.addSource(source)

            mapView.style?.setImage(icon.withRenderingMode(.alwaysTemplate), forName: "icon")

            addSymbolLayer(mapView: mapView, source: source, icon: icon)
            addCircleLayer(mapView: mapView, source: source, icon: icon)
            addNumbersLayer(mapView: mapView, source: source, icon: icon)
        }
    }

    func addSymbolLayer(mapView: MLNMapView, source: MLNShapeSource, icon: UIImage) {
        let ports = MLNSymbolStyleLayer(identifier: "ports", source: source)
        ports.iconImageName = NSExpression(forConstantValue: "icon")
        ports.iconColor = NSExpression(forConstantValue: UIColor.darkGray.withAlphaComponent(0.9))
        ports.predicate = NSPredicate(format: "cluster != YES")
        ports.iconAllowsOverlap = NSExpression(forConstantValue: true)
        mapView.style?.addLayer(ports)
    }

    func addCircleLayer(mapView: MLNMapView, source: MLNShapeSource, icon: UIImage) {
        let stops = [
            20: UIColor.lightGray,
            50: UIColor.orange,
            100: UIColor.red,
            200: UIColor.purple
        ]

        let circlesLayer = MLNCircleStyleLayer(identifier: "clusteredPorts", source: source)
        circlesLayer.circleRadius = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
        circlesLayer.circleOpacity = NSExpression(forConstantValue: 0.75)
        circlesLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white.withAlphaComponent(0.75))
        circlesLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
        circlesLayer.circleColor = NSExpression(format: "mgl_step:from:stops:(point_count, %@, %@)", UIColor.lightGray, stops)
        circlesLayer.predicate = NSPredicate(format: "cluster == YES")
        mapView.style?.addLayer(circlesLayer)
    }

    func addNumbersLayer(mapView: MLNMapView, source: MLNShapeSource, icon: UIImage) {
        let numbersLayer = MLNSymbolStyleLayer(identifier: "clusteredPortsNumbers", source: source)
        numbersLayer.textColor = NSExpression(forConstantValue: UIColor.white)
        numbersLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: Double(icon.size.width) / 2))
        numbersLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        numbersLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
        numbersLayer.predicate = NSPredicate(format: "cluster == YES")
        mapView.style?.addLayer(numbersLayer)
    }
}
