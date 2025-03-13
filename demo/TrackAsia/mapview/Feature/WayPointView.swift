//
//  WayPointView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 26/12/2023.
//

import TrackAsia
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapKit

struct WaypointView {
    
    weak var mapView: MLNMapView?

    init(mapView: MLNMapView) {
        self.mapView = mapView
    }

    static func view(for annotation: MLNAnnotation) -> MLNAnnotationView? {
        guard let pointAnnotation = annotation as? MLNPointAnnotation else {
            return nil
        }

        let annotationView = MLNAnnotationView(reuseIdentifier: "pointAnnotation")
        let iconSize = CGSize(width: 60, height: 60)

        if let title = pointAnnotation.title {
            let label = UILabel(frame: CGRect(x: 8, y: -16, width: 16, height: 16))
            label.text = title
            label.textColor = UIColor.white
            label.textAlignment = .center
            label.backgroundColor = UIColor.blue
            label.layer.cornerRadius = label.frame.width / 2
            label.layer.masksToBounds = true

            let customView = UIView(frame: CGRect(x: -16, y: -24, width: iconSize.width, height: iconSize.height))
            customView.addSubview(label)
            customView.addSubview(UIImageView(image: UIImage(named: "ic_location")))
            annotationView.addSubview(customView)

            return annotationView
        }

        return nil
    }
    
    static func addWaypoints(mapView: MLNMapView, waypoints: [Waypoint]) {
        for (index, waypoint) in waypoints.enumerated() {
            let marker = MLNPointAnnotation()
            marker.coordinate = waypoint.coordinate
            marker.title = String(index + 1)
            mapView.addAnnotation(marker)
        }
    }
    
    static func onWaypoints(mapView: MLNMapView, waypoints: [Waypoint]) {
        if waypoints.count >= 2 {
            let origin = waypoints[0]
            let destination = waypoints.last!
            
            let originMarker = MLNPointAnnotation()
            originMarker.coordinate = origin.coordinate
            originMarker.title = "Origin"
            mapView.addAnnotation(originMarker)
            
            let destinationMarker = MLNPointAnnotation()
            destinationMarker.coordinate = destination.coordinate
            destinationMarker.title = "Destination"
            mapView.addAnnotation(destinationMarker)
        }
    }
}
