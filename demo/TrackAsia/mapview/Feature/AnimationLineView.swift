//
//  AnimationLineView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 27/12/2023.
//

import Foundation
import TrackAsia
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapKit
import Combine
import SwiftUI
import CoreGraphics

class PolylineView: ObservableObject {
    @Published var allCoordinates: [CLLocationCoordinate2D]?
    @Published var currentIndex = 1
    @Published var polylineSource: MLNShapeSource?
    @Published var carSource: MLNShapeSource?
    @Published var isAnimating = false
    
    var lineLayer: MLNLineStyleLayer?
    var style: MLNStyle?
    private var timer: Timer?
    private var currentPolyline: MLNPolyline?
    private var currentMapView: MLNMapView?
    
    init(coordinates: [CLLocationCoordinate2D]) {
        self.allCoordinates = coordinates
    }
    
    func startAnimation() {
        animatePolyline()
    }
    
    func removeExistingSourceIfNeeded(withIdentifier identifier: String, style: MLNStyle, mapview: MLNMapView) {
        if let existingSource = style.source(withIdentifier: identifier) {
            style.removeSource(existingSource)
            mapview.setNeedsLayout()
        }
    }
    
    func addPolyline(to style: MLNStyle, mapview: MLNMapView) {
        // Tạo polyline từ tất cả các tọa độ
        let polyline = MLNPolyline(coordinates: allCoordinates!, count: UInt(allCoordinates!.count))
        
        // Tạo source cho polyline tổng thể
        let fullSource = MLNShapeSource(identifier: "animation-source", shape: polyline, options: [MLNShapeSourceOption.lineDistanceMetrics: true])
        style.addSource(fullSource)
        
        // Tạo layer cho polyline tổng thể
        let fullLayer = MLNLineStyleLayer(identifier: "animation-layer", source: fullSource)
        fullLayer.lineJoin = NSExpression(forConstantValue: "round")
        fullLayer.lineCap = NSExpression(forConstantValue: "round")
        fullLayer.lineColor = NSExpression(forConstantValue: UIColor.blue.withAlphaComponent(0.7))
        fullLayer.lineWidth = NSExpression(forConstantValue: 4)
        style.addLayer(fullLayer)
        
        // Lưu lại nguồn và layer để có thể xóa sau này
        polylineSource = fullSource
        lineLayer = fullLayer
        
        // Kiểm tra và cập nhật car symbol tương tự
        addCarSymbol(to: style)
        
        print("Animation polyline setup completed. Source exists: \(style.source(withIdentifier: "animation-source") != nil)")
    }
    
    func addCarSymbol(to style: MLNStyle) {
        let symbolSourceIdentifier = "carSource"
        
        if let existingCarSource = style.source(withIdentifier: symbolSourceIdentifier) as? MLNShapeSource {
            // Chỉ lưu lại reference đến source hiện tại
            carSource = existingCarSource
        } else {
            // Tạo mới source nếu chưa tồn tại
            let symbolSource = MLNShapeSource(identifier: symbolSourceIdentifier, shape: nil, options: nil)
            style.addSource(symbolSource)
            carSource = symbolSource
            
            // Thêm layer mới nếu chưa tồn tại
            if style.layer(withIdentifier: symbolSourceIdentifier) == nil {
                let symbolLayer = MLNSymbolStyleLayer(identifier: symbolSourceIdentifier, source: symbolSource)
                configureCarSymbolLayer(symbolLayer)
                style.addLayer(symbolLayer)
            }
        }
        
        print("Car symbol setup completed. Source exists: \(style.source(withIdentifier: symbolSourceIdentifier) != nil)")
    }
    
    func configureCarSymbolLayer(_ symbolLayer: MLNSymbolStyleLayer) {
        symbolLayer.iconImageName = NSExpression(forConstantValue: "ic_taxi")
        symbolLayer.iconScale = NSExpression(forConstantValue: 50)
        
        // Điều chỉnh các thuộc tính của lớp biểu tượng để cải thiện sự nhìn thấy
        symbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        symbolLayer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        
        // Sửa lỗi: Thay vì sử dụng mảng, sử dụng offset point
        let offsetPoint = CGPoint(x: 0, y: -20)
        symbolLayer.iconOffset = NSExpression(forConstantValue: offsetPoint)
    }
    
    func animatePolyline() {
        // Dừng timer cũ nếu có
        stopAnimation()
        
        // Bắt đầu từ đầu
        currentIndex = 0
        isAnimating = true
        
        // Tạo timer để cập nhật animation
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Tăng chỉ số tọa độ
            self.currentIndex += 1
            if self.currentIndex >= self.allCoordinates!.count {
                self.currentIndex = 0
            }
            
            // Cập nhật hiển thị
            self.updateAnimation()
        }
        
        print("Animation started with \(allCoordinates!.count) points")
    }
    
    func updateAnimation() {
        // Cập nhật animation progress
        let progress = CGFloat(currentIndex) / CGFloat(allCoordinates!.count)
        updatePolylineWithProgress(progress: progress)
        
        // Kiểm tra xem có phần tử cuối cùng không
        if let allCoords = allCoordinates, currentIndex < allCoords.count {
            let lastCoordinate = allCoords[currentIndex]
            updateCarPosition(lastCoordinate, in: style)
        }
    }
    
    func updatePolylineWithProgress(progress: CGFloat) {
        guard let allCoords = allCoordinates, !allCoords.isEmpty else { return }
        
        // Tính toán tọa độ dựa trên progress
        let index = Int(progress * CGFloat(allCoords.count - 1))
        let interpolatedCoordinate = interpolateCoordinate(from: allCoords[index], to: allCoords[(index + 1) % allCoords.count], progress: progress - CGFloat(index) / CGFloat(allCoords.count - 1))
        
        // Cập nhật polyline
        updatePolylineWithCoordinates(coordinates: [interpolatedCoordinate])
    }
    
    func interpolateCoordinate(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, progress: CGFloat) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * progress
        let lon = start.longitude + (end.longitude - start.longitude) * progress
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    func updateCarPosition(_ coordinate: CLLocationCoordinate2D, in style: MLNStyle?) {
        guard let style = style else { return }
        
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
        guard !coordinates.isEmpty, let polylineSource = polylineSource else { return }
        
        // Tạo bản sao mutable từ coordinates để tránh lỗi
        var mutableCoordinates = coordinates
        
        // Sử dụng mutableCoordinates để tạo MLNPolylineFeature
        let polyline = MLNPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        polylineSource.shape = polyline
    }
    
    // Hàm dừng animation đã được chỉnh sửa
    func stopAnimation() {
        print("Stopping animation...")
        
        // Dừng timer
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        // Xóa polyline từ source
        if let source = polylineSource {
            source.shape = nil
            print("Cleared polyline source")
        }
        
        // Xóa vị trí xe
        if let carSrc = carSource {
            carSrc.shape = nil
            print("Cleared car source")
        }
        
        // Reset trạng thái
        currentIndex = 0
        isAnimating = false
        
        print("Animation stopped successfully")
    }
    
    func removeFromMap() {
        // Dừng animation
        stopAnimation()
        
        // Xóa các layer và source
        if let style = style {
            if let layer = lineLayer {
                style.removeLayer(layer)
            }
            if let source = polylineSource {
                style.removeSource(source)
            }
            if let source = carSource {
                style.removeSource(source)
            }
        }
        
        // Xóa danh sách
        allCoordinates = nil
        polylineSource = nil
        lineLayer = nil
        carSource = nil
        
        print("Animation removed from map")
    }
}
