import UIKit
import TrackAsia

/// DirectTouchMapView là một lớp trung gian giúp bắt các sự kiện touch trên view
/// trước khi chúng được chuyển đến MLNMapView, cho phép kiểm soát tương tác người dùng
public class DirectTouchMapView: UIView {
    /// MLNMapView được bọc lại để kiểm soát các sự kiện
    public var mapView: MLNMapView? {
        didSet {
            if let mapView = mapView {
                if mapView.superview != self {
                    oldValue?.removeFromSuperview()
                    addSubview(mapView)
                    mapView.frame = bounds
                    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                }
            }
        }
    }
    
    /// Khởi tạo với frame
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    /// Khởi tạo từ decoder
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
    }
    
    /// Override phương thức hitTest để kiểm soát luồng touch
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Nếu sự kiện không phải là touch, chuyển đến superview
        guard event?.type == .touches else {
            return super.hitTest(point, with: event)
        }
        
        // Lấy view tại điểm chạm
        let view = super.hitTest(point, with: event)
        
        // Nếu view không phải là MLNMapView, trả về view đó để xử lý sự kiện
        if view != mapView {
            return view
        }
        
        // Trả về self để tự xử lý sự kiện touch trên map view
        return self
    }
    
    /// Chuyển sự kiện touch đến map view
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapView?.touchesBegan(touches, with: event)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapView?.touchesMoved(touches, with: event)
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapView?.touchesEnded(touches, with: event)
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mapView?.touchesCancelled(touches, with: event)
    }
} 