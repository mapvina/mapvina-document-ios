//
//  RouteHandler.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 26/12/2023.
//

import TrackAsia
import MapboxCoreNavigation
import MapboxDirections
import MapboxDirectionsObjc

typealias RouteRequestSuccess = (([Route]) -> Void)
typealias RouteRequestFailure = ((Error) -> Void)

class RouteHandler: ObservableObject {
    private var mapView: MLNMapView
    @Published var routes: [Route]?
    @Published var waypoints: [Waypoint] = []
    private var routeOptions: NavigationRouteOptions?
    @Published var currentRoute: Route?
    
    var routesUpdatedCallback: (([Route]?, [Waypoint]?) -> Void)?

    init(mapView: MLNMapView) {
        self.mapView = mapView
    }

    func handleRequestRoute(success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        guard waypoints.count > 0 else { return }
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: MBDirectionsProfileIdentifier.automobile)
        requestRoute(with: options, success: success, failure: failure)
    }

    private func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        let handler: Directions.RouteCompletionHandler = { waypoints, potentialRoutes, potentialError in
            if let error = potentialError {
                print("Error calculating route: \(error)")
                failure?(error)
            }
//            print("waypoints calculated successfully: \(waypoints)")
            if let routes = potentialRoutes {
//                print("Route calculated successfully: \(routes)")
                
//                if let jsonData = try? JSONSerialization.data(withJSONObject: routes, options: []),
//                    let decodedRoute = try? JSONDecoder().decode(Routelog.self, from: jsonData),
//                    let firstStep = decodedRoute.legs.first?.steps.first {
//                    let coordinates = firstStep.maneuver.location
//                    let formattedCoordinates = "[\(coordinates[0]), \(coordinates[1])]"
//                    print(formattedCoordinates)
//                } else {
//                    print("Không có thông tin tọa độ.")
//                }
                success(routes)
            }
            
        }

        Directions.shared.calculate(options, completionHandler: handler)
    }

    lazy var defaultSuccess: RouteRequestSuccess = { [weak self] routes in
        guard let current = routes.first else { return }
        self?.routes = routes
        self?.waypoints = current.routeOptions.waypoints
        self?.routesUpdatedCallback?(self?.routes, self?.waypoints)
    }

    lazy var defaultFailure: RouteRequestFailure = { error in
        print(error.localizedDescription)
    }
    
    struct Routelog: Decodable {
        let legs: [Leg]
    }

    struct Leg: Decodable {
        let steps: [Step]
    }

    struct Step: Decodable {
        let maneuver: Maneuver
    }

    struct Maneuver: Decodable {
        let location: [Double]
    }

    func requestRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (Route?) -> Void) {
        let originWaypoint = Waypoint(coordinate: origin)
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        routeOptions = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        
        Directions.shared.calculate(routeOptions!) { (waypoints, routes, error) in
            if let error = error {
                print("Error calculating route: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let route = routes?.first else {
                completion(nil)
                return
            }
            
            self.currentRoute = route
            completion(route)
        }
    }
    
    func addRoute(_ route: Route) {
        guard let coordinates = route.coordinates else { return }
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        mapView.add(polyline)
    }
}

