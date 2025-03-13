//
//  AnimationLineView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 27/12/2023.
//

import Foundation
import TrackAsia

class AnimationLineView: ObservableObject {
    @Published var allCoordinates: [CLLocationCoordinate2D]!
    @Published var currentIndex = 1
    @Published var polylineSource: MLNShapeSource?
    @Published var carSource: MLNShapeSource?
    
    var symbolLayer: MLNSymbolStyleLayer?
    var style: MLNStyle!
    private var timer: Timer?
    
    init() {
        allCoordinates = coordinates
    }
    
    func removeExistingSourceIfNeeded(withIdentifier identifier: String, style: MLNStyle, mapview: MLNMapView) {
        if let existingSource = style.source(withIdentifier: identifier) {
            style.removeSource(existingSource)
            mapview.setNeedsLayout()
        }
    }
    
    func addPolyline(to style: MLNStyle, mapview: MLNMapView) {
        //        removeExistingSourceIfNeeded(withIdentifier: "polyline", style: style, mapview: mapview)
        //        removeExistingSourceIfNeeded(withIdentifier: "carSource", style: style, mapview: mapview)
        let sourceIdentifier = "polyline"
        if let existingSource = style.source(withIdentifier: sourceIdentifier) as? MLNShapeSource {
            existingSource.shape = nil
            polylineSource = existingSource
        } else {
            let source = MLNShapeSource(identifier: sourceIdentifier, shape: nil, options: nil)
            style.addSource(source)
            polylineSource = source
            let layer = MLNLineStyleLayer(identifier: sourceIdentifier, source: source)
            configurePolylineLayer(layer)
            style.addLayer(layer)
        }
        addCarSymbol(to: style)
    }
    
    func configurePolylineLayer(_ layer: MLNLineStyleLayer) {
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineColor = NSExpression(forConstantValue: UIColor.blue)
        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [14: 5, 18: 20])
    }
    
    func addCarSymbol(to style: MLNStyle) {
        let symbolSourceIdentifier = "carSource"
        
        if let existingCarSource = style.source(withIdentifier: symbolSourceIdentifier) as? MLNShapeSource {
        } else {
            let symbolSource = MLNShapeSource(identifier: symbolSourceIdentifier, shape: nil, options: nil)
            style.addSource(symbolSource)
            carSource = symbolSource
            
            // Thêm layer
            let symbolLayer = MLNSymbolStyleLayer(identifier: symbolSourceIdentifier, source: symbolSource)
            configureCarSymbolLayer(symbolLayer)
            style.addLayer(symbolLayer)
        }
    }
    
    func configureCarSymbolLayer(_ symbolLayer: MLNSymbolStyleLayer) {
        symbolLayer.iconImageName = NSExpression(forConstantValue: "ic_taxi")
        symbolLayer.iconScale = NSExpression(forConstantValue: 50)
        
        // Điều chỉnh các thuộc tính của lớp biểu tượng để cải thiện sự nhìn thấy
        symbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        symbolLayer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        symbolLayer.iconOffset = NSExpression(forConstantValue: NSValue(cgVector: CGVector(dx: 0, dy: -20))) // Điều chỉnh vị trí nếu cần
    }
    
    func animatePolyline() {
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    @objc func tick() {
        if currentIndex > allCoordinates.count {
            timer?.invalidate()
            timer = nil
            return
        }
        
        let coordinates = Array(allCoordinates[0..<currentIndex])
        updatePolylineWithCoordinates(coordinates: coordinates)
        updateCarPosition(coordinates.last!, in: style)
        currentIndex += 1
    }
    
    func updateCarPosition(_ coordinate: CLLocationCoordinate2D, in style: MLNStyle) {
        let carFeature = MLNPointFeature()
        carFeature.coordinate = coordinate
        if let shapeSource = style.source(withIdentifier: "carSource") as? MLNShapeSource {
            shapeSource.shape = carFeature
            print("Car position updated successfully.")
        } else {
            print("Error: Unable to find shape source with identifier 'carSource'.")
        }
    }
    
    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        let polyline = MLNPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        polylineSource?.shape = polyline
    }
    
    let coordinates = [
        [106.608252, 10.727316],
        [106.607953, 10.727129],
        [106.607311, 10.728145],
        [106.607548, 10.728294],
        [106.608252, 10.727316],
        [106.609417, 10.729534],
        [106.60958, 10.729643],
        [106.609702, 10.729728],
        [106.611965, 10.732878],
        [106.614165, 10.736535],
        [106.614676, 10.737384],
        [106.615152, 10.738165],
        [106.615219, 10.738268],
        [106.616387, 10.739366],
        [106.616475, 10.73944],
        [106.617072, 10.739947],
        [106.618389, 10.74109],
        [106.619167, 10.741742],
        [106.621177, 10.743412],
        [106.621359, 10.743558],
        [106.62173, 10.743868],
        [106.623413, 10.745219],
        [106.623724, 10.745351],
        [106.623778, 10.745345],
        [106.623929, 10.745415],
        [106.623956, 10.745648],
        [106.624232, 10.74595],
        [106.626471, 10.74783],
        [106.626661, 10.74799],
        [106.628055, 10.749088],
        [106.628807, 10.749688],
        [106.630693, 10.751134],
        [106.632456, 10.752527],
        [106.633975, 10.753587],
        [106.634033, 10.753619],
        [106.634261, 10.753699],
        [106.634432, 10.753664],
        [106.634604, 10.753723],
        [106.634745, 10.753986],
        [106.635012, 10.754256],
        [106.635499, 10.754442],
        [106.635673, 10.754449],
        [106.638145, 10.754648],
        [106.63827, 10.754637],
        [106.63827, 10.754637],
        [106.639661, 10.754493],
        [106.640038, 10.754457],
        [106.641867, 10.754228],
        [106.64256, 10.754161],
        [106.643058, 10.754111],
        [106.643154, 10.754104],
        [106.643176, 10.754297],
        [106.643246, 10.754657],
        [106.64342, 10.754771],
        [106.644688, 10.755483],
        [106.645141, 10.755733],
        [106.645582, 10.755976],
        [106.646617, 10.756536],
        [106.646851, 10.756663],
        [106.648994, 10.757819],
        [106.649406, 10.758047],
        [106.649613, 10.758158],
        [106.64987, 10.758301],
        [106.650108, 10.758429],
        [106.65071, 10.758754],
        [106.6512, 10.759016],
        [106.651403, 10.759121],
        [106.651485, 10.759167],
        [106.652587, 10.75977],
        [106.65311, 10.760044],
        [106.653263, 10.760132],
        [106.65334, 10.760176],
        [106.656803, 10.762053],
        [106.657001, 10.762159],
        [106.657103, 10.762214],
        [106.658679, 10.763079],
        [106.659949, 10.763774],
        [106.660032, 10.763819],
        [106.660847, 10.764253],
        [106.661541, 10.764624],
        [106.662427, 10.765096],
        [106.66275, 10.765268],
        [106.662958, 10.765379],
        [106.663515, 10.765676],
        [106.664038, 10.765954],
        [106.664808, 10.766383],
        [106.665185, 10.766587],
        [106.665389, 10.766745],
        [106.669904, 10.76919],
        [106.670104, 10.769264],
        [106.670204, 10.769315],
        [106.670445, 10.769446],
        [106.67078, 10.769633],
        [106.671049, 10.769758],
        [106.673074, 10.770855],
        [106.711648, 10.808065],
        [106.711732, 10.808356],
        [106.711819, 10.808599],
        [106.711985, 10.809029],
        [106.712166, 10.808972]
    ].map({ CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) })
}
