import Foundation
import CoreLocation
import MapVina

class DebugUtils {
    static var isDebugMode = true
    private static var tapHistory: [(date: Date, coordinate: CLLocationCoordinate2D, processed: Bool)] = []
    
    static func logTapEvent(coordinate: CLLocationCoordinate2D, processed: Bool = false) {
        guard isDebugMode else { return }
        
        // Lưu lịch sử tap
        tapHistory.append((Date(), coordinate, processed))
        
        // In thông tin về sự kiện tap
        print("🔍 DEBUG - Tap Event:")
        print("  - Time: \(Date().formatted(date: .omitted, time: .standard))")
        print("  - Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        print("  - Processed: \(processed ? "✅" : "❌")")
        print("  - Recent history: \(tapHistory.count) events")
    }
    
    static func traceMapViewOperation(operation: String, details: String? = nil) {
        guard isDebugMode else { return }
        
        print("🗺️ MAP TRACE - \(operation)")
        if let details = details {
            print("  └─ \(details)")
        }
    }
    
    static func logWaypointStatus(waypoints: [CLLocationCoordinate2D], route: Any?, canNavigate: Bool) {
        guard isDebugMode else { return }
        
        print("📊 WAYPOINT STATUS:")
        print("  - Total waypoints: \(waypoints.count)")
        for (index, point) in waypoints.enumerated() {
            print("  - Point #\(index+1): (\(point.latitude), \(point.longitude))")
        }
        print("  - Route calculated: \(route != nil ? "✅" : "❌")")
        print("  - Can navigate: \(canNavigate ? "✅" : "❌")")
    }
    
    static func trackGestureSetup(mapView: MLNMapView?, mode: String) {
        guard isDebugMode else { return }
        
        print("👆 GESTURE SETUP:")
        print("  - Map view instance: \(mapView != nil ? "✅" : "❌")")
        print("  - Current mode: \(mode)")
        if let recognizers = mapView?.gestureRecognizers {
            print("  - Gesture recognizers: \(recognizers.count)")
            for (i, recognizer) in recognizers.enumerated() {
                print("    [\(i+1)] \(type(of: recognizer)) - Enabled: \(recognizer.isEnabled)")
            }
        } else {
            print("  - No gesture recognizers found")
        }
    }
    
    static func trackHandleWaypointTap(at coordinate: CLLocationCoordinate2D, inMode mode: String) {
        guard isDebugMode else { return }
        
        print("🚩 handleWaypointTap CALLED:")
        print("  - Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        print("  - Current mode: \(mode)")
        print("  - Stack trace:")
        
        // In một stack trace đơn giản
        let symbols = Thread.callStackSymbols
        for (i, symbol) in symbols.prefix(6).enumerated() {
            if i > 0 { // Bỏ qua frame hiện tại
                print("    \(symbol)")
            }
        }
    }
} 