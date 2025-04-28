//
//  ClusterView.swift
//  TrackAsiaDemo
//
//  Created by SangNguyen on 26/12/2023.
//

import UIKit
import TrackAsia
import CoreLocation

class ClusterView: NSObject, MLNMapViewDelegate {
    var mapView: MLNMapView?
    private var previousDelegate: MLNMapViewDelegate?
    private var clusterSourceCreated = false
    
    init(mapView: MLNMapView) {
        super.init()
        self.mapView = mapView
        
        // Lưu delegate hiện tại
        self.previousDelegate = mapView.delegate
        
        // Thiết lập self làm delegate
        mapView.delegate = self
        
        // Thiết lập cluster
        setupCluster()
        
        print("🔄 ClusterView đã được khởi tạo")
    }
    
    func setupCluster() {
        guard let mapView = mapView else { return }
        
        // Xóa source và layer hiện có nếu có
        cleanupExistingLayers()
        
        // Tạo source từ URL GeoJSON với cấu hình clustering
        do {
            if !clusterSourceCreated {
                let source = MLNShapeSource(identifier: "clusteredPorts",
                                          url: URL(string: "https://panel.hainong.vn/api/v2/diagnostics/pets_map.geojson")!,
                                          options: [.clustered: true, 
                                                    .clusterRadius: 50,
                                                    .maximumZoomLevelForClustering: 14])
                
                mapView.style?.addSource(source)
                clusterSourceCreated = true
                
                // Tạo các layer cho clusters
                createClusterLayers(source: source)
                
                print("✅ Cluster source và layers đã được tạo")
            } else {
                print("⚠️ Cluster source đã tồn tại, không tạo lại")
            }
        } catch {
            print("❌ Lỗi khi thiết lập cluster: \(error)")
        }
    }
    
    private func cleanupExistingLayers() {
        guard let mapView = mapView, let style = mapView.style else { return }
        
        // Xóa tất cả các layer liên quan đến cluster
        let layerIds = [
            "unclustered-points", "cluster-circles", "cluster-labels",
            "cluster-circles-small", "cluster-circles-medium", "cluster-circles-large"
        ]
        
        for layerId in layerIds {
            if let layer = style.layer(withIdentifier: layerId) {
                print("Removing layer: \(layerId)")
                style.removeLayer(layer)
            }
        }
        
        // Xóa nguồn dữ liệu nếu cần
        if let source = style.source(withIdentifier: "clusteredPorts") {
            print("Removing source: clusteredPorts")
            style.removeSource(source)
            clusterSourceCreated = false
        }
    }
    
    private func createClusterLayers(source: MLNShapeSource) {
        guard let mapView = mapView else { return }
        
        // 1. Layer cho các điểm đơn lẻ - hiển thị dưới dạng circle nhỏ màu đỏ
        let singlePointLayer = MLNCircleStyleLayer(identifier: "unclustered-points", source: source)
        singlePointLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
        singlePointLayer.circleRadius = NSExpression(forConstantValue: 8)
        singlePointLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
        singlePointLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
        singlePointLayer.predicate = NSPredicate(format: "cluster != YES")
        mapView.style?.addLayer(singlePointLayer)
        
        // 2. Layer cho tất cả các cluster - hiển thị dưới dạng circle màu đỏ
        let clusterLayer = MLNCircleStyleLayer(identifier: "cluster-circles", source: source)
        clusterLayer.circleColor = NSExpression(forConstantValue: UIColor.red)
        clusterLayer.circleOpacity = NSExpression(forConstantValue: 0.9)
        clusterLayer.circleStrokeWidth = NSExpression(forConstantValue: 2)
        clusterLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
        clusterLayer.predicate = NSPredicate(format: "cluster == YES")
        
        // Kích thước thay đổi dựa trên số lượng điểm trong cluster
        clusterLayer.circleRadius = NSExpression(format: "12 + log(point_count) * 3")
        
        mapView.style?.addLayer(clusterLayer)
        
        // 3. Layer cho số lượng điểm trong cluster
        let labelsLayer = MLNSymbolStyleLayer(identifier: "cluster-labels", source: source)
        labelsLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
        labelsLayer.textColor = NSExpression(forConstantValue: UIColor.white)
        labelsLayer.textFontSize = NSExpression(forConstantValue: 12)
        labelsLayer.textFontNames = NSExpression(forConstantValue: ["Helvetica Bold", "Arial Unicode MS Bold"])
        labelsLayer.symbolPlacement = NSExpression(forConstantValue: "point")
        labelsLayer.textAllowsOverlap = NSExpression(forConstantValue: true)
        labelsLayer.textIgnoresPlacement = NSExpression(forConstantValue: true)
        labelsLayer.textJustification = NSExpression(forConstantValue: "center")
        labelsLayer.textAnchor = NSExpression(forConstantValue: "center")
        labelsLayer.predicate = NSPredicate(format: "cluster == YES")
        mapView.style?.addLayer(labelsLayer)
    }
    
    // MARK: - MLNMapViewDelegate methods
    
    func mapView(_ mapView: MLNMapView, didTapOn feature: MLNFeature) {
        // Kiểm tra nếu feature là một cluster
        if let cluster = feature.attribute(forKey: "cluster") as? Bool, 
           cluster == true,
           let pointCount = feature.attribute(forKey: "point_count") as? NSNumber {
            
            print("Tapped on cluster with \(pointCount) points")
            
            // Lấy tọa độ của cluster
            let coordinate = feature.coordinate
            
            // Tính toán mức zoom phù hợp dựa trên số lượng điểm
            let currentZoom = mapView.zoomLevel
            let zoomIncrement: Double
            
            if pointCount.intValue > 100 {
                zoomIncrement = 3.0  // Zoom nhiều hơn cho cluster lớn
            } else if pointCount.intValue > 20 {
                zoomIncrement = 2.0  // Zoom vừa phải cho cluster trung bình
            } else {
                zoomIncrement = 1.5  // Zoom ít hơn cho cluster nhỏ
            }
            
            let newZoom = min(currentZoom + zoomIncrement, mapView.maximumZoomLevel)
            
            // Zoom vào cluster với animation
            mapView.setCenter(coordinate, zoomLevel: newZoom, animated: true)
            
            return
        }
        
        // Chuyển tiếp sự kiện tap cho delegate trước đó nếu không phải cluster
//        previousDelegate?.mapView?(mapView, didTapOn: feature)
    }
    
    // Chuyển tiếp các phương thức delegate khác
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        previousDelegate?.mapView?(mapView, didFinishLoading: style)
        
        // Sau khi style đã tải xong, thiết lập lại cluster nếu cần
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupCluster()
        }
    }
    
    func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        previousDelegate?.mapView?(mapView, regionDidChangeWith: reason, animated: animated)
    }
    
    // Phương thức công khai để gọi dọn dẹp từ bên ngoài
    public func cleanup() {
        // Khôi phục delegate ban đầu
        if let mapView = mapView {
            print("♻️ Khôi phục delegate ban đầu và dọn dẹp tài nguyên")
            cleanupExistingLayers()
            mapView.delegate = previousDelegate
            self.mapView = nil
            self.previousDelegate = nil
        }
    }
    
    // Swift deinit tự động
    deinit {
        cleanup()
        print("♻️ ClusterView deinit")
    }
}
