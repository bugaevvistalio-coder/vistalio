//
//  UIView+Utils.swift
//  Vistalio
//
//  Created by Julia Konkova on 20.03.2026.
//

import UIKit

extension UIView {
    
    func xibSetup() -> UIView {
        backgroundColor = UIColor.clear
        let view = loadNib()
        view.frame = bounds
        addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                      options: [],
                                                      metrics: nil,
                                                      views: ["childView": view]))
        return view
    }
    
    func loadNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as! UIView
    }
    
    func setShadow(offset:CGSize = CGSize(width: 0, height: 5), radius: CGFloat = 5, cornerRadius:CGFloat = 12, color: UIColor = UIColor.black, shadowOpacity:Float = 0.05) {
        layer.cornerRadius = cornerRadius
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shadowOpacity = shadowOpacity
    }
    
    func addShadow(offset:CGSize = CGSize(width: 0, height: 5), radius: CGFloat = 5, cornerRadius:CGFloat = 12, color: UIColor = UIColor.black, shadowOpacity:Float = 0.05, bounds: CGRect? = nil) {
        layer.sublayers?.filter({ $0.name == "ShadowLayer" }).forEach({ $0.removeFromSuperlayer() })
        
        let shadowLayer = CAShapeLayer()
        shadowLayer.name = "ShadowLayer"
        
        shadowLayer.cornerRadius = cornerRadius
        shadowLayer.shadowColor = color.cgColor
        shadowLayer.shadowRadius = radius
        shadowLayer.shadowOffset = offset
        shadowLayer.shadowOpacity = shadowOpacity
        shadowLayer.bounds = bounds ?? self.bounds
        layer.insertSublayer(shadowLayer, at: 0)
    }
    
    func addDashedBorder(color: UIColor = .black, lineWidth: CGFloat = 1, dashPattern: [NSNumber]? = [4, 2], cornerRadius: CGFloat = 0, fixedBounds: CGRect? = nil) {
        layer.sublayers?.filter({ $0.name == "DashedBorder" }).forEach({ $0.removeFromSuperlayer() })

        let shapeLayer = CAShapeLayer()
        shapeLayer.name = "DashedBorder"
        
        let bounds = fixedBounds ?? bounds
        
        let path = CGMutablePath()

        // Points - Eight points that define the round border. Each border is defined by two points.
        let topLeftPoint = CGPoint(x: cornerRadius, y: 0)
        let topRightPoint = CGPoint(x: bounds.size.width - cornerRadius, y: 0)
        let middleRightTopPoint = CGPoint(x: bounds.size.width, y: cornerRadius)
        let middleRightBottomPoint = CGPoint(x: bounds.size.width, y: bounds.size.height - cornerRadius)
        let bottomRightPoint = CGPoint(x: bounds.size.width - cornerRadius, y: bounds.size.height)
        let bottomLeftPoint = CGPoint(x: cornerRadius, y: bounds.size.height)
        let middleLeftBottomPoint = CGPoint(x: 0, y: bounds.size.height - cornerRadius)
        let middleLeftTopPoint = CGPoint(x: 0, y: cornerRadius)

        // Points - Four points that are the center of the corners borders.
        let cornerTopRightCenter = CGPoint(x: bounds.size.width - cornerRadius, y: cornerRadius)
        let cornerBottomRightCenter = CGPoint(x: bounds.size.width - cornerRadius, y: bounds.size.height - cornerRadius)
        let cornerBottomLeftCenter = CGPoint(x: cornerRadius, y: bounds.size.height - cornerRadius)
        let cornerTopLeftCenter = CGPoint(x: cornerRadius, y: cornerRadius)

        // Angles - The corner radius angles.
        let topRightStartAngle = CGFloat(Double.pi * 3 / 2)
        let topRightEndAngle = CGFloat(0)
        let bottomRightStartAngle = CGFloat(0)
        let bottmRightEndAngle = CGFloat(Double.pi / 2)
        let bottomLeftStartAngle = CGFloat(Double.pi / 2)
        let bottomLeftEndAngle = CGFloat(Double.pi)
        let topLeftStartAngle = CGFloat(Double.pi)
        let topLeftEndAngle = CGFloat(Double.pi * 3 / 2)

        // Drawing a border around a view.
        path.move(to: topLeftPoint)
        path.addLine(to: topRightPoint)
        path.addArc(center: cornerTopRightCenter,
                    radius: cornerRadius,
                    startAngle: topRightStartAngle,
                    endAngle: topRightEndAngle,
                    clockwise: false)
        path.addLine(to: middleRightBottomPoint)
        path.addArc(center: cornerBottomRightCenter,
                    radius: cornerRadius,
                    startAngle: bottomRightStartAngle,
                    endAngle: bottmRightEndAngle,
                    clockwise: false)
        path.addLine(to: bottomLeftPoint)
        path.addArc(center: cornerBottomLeftCenter,
                    radius: cornerRadius,
                    startAngle: bottomLeftStartAngle,
                    endAngle: bottomLeftEndAngle,
                    clockwise: false)
        path.addLine(to: middleLeftTopPoint)
        path.addArc(center: cornerTopLeftCenter,
                    radius: cornerRadius,
                    startAngle: topLeftStartAngle,
                    endAngle: topLeftEndAngle,
                    clockwise: false)

        // Path is set as the shapeLayer object's path.
        shapeLayer.path = path;
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.frame = bounds
        shapeLayer.masksToBounds = false
        shapeLayer.setValue(0, forKey: "isCircle")
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineDashPattern = dashPattern
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        
        layer.addSublayer(shapeLayer)
    }
    
    func toImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { ctx in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
    
    func makeTransparentHole(at center: CGPoint, radius: CGFloat) {
        let path = UIBezierPath(rect: self.bounds)
        let holePath = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: 0,
                                    endAngle: 2 * .pi,
                                    clockwise: true)
        
        path.append(holePath)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        
        self.layer.mask = maskLayer
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    func setGradientLayer(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint, cornerRadius: CGFloat, bounds: CGRect? = nil) {
        layer.sublayers?.filter({ $0.name == "GradientLayer" }).forEach({ $0.removeFromSuperlayer() })
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientLayer"
        gradientLayer.colors = colors.map({$0.cgColor})
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.frame = bounds ?? self.bounds
        gradientLayer.cornerRadius = cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setGradientLayer(colors: [UIColor], locations: [NSNumber], cornerRadius: CGFloat, bounds: CGRect? = nil) {
        layer.sublayers?.filter({ $0.name == "GradientLayer" }).forEach({ $0.removeFromSuperlayer() })
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "GradientLayer"
        gradientLayer.colors = colors.map({$0.cgColor})
        gradientLayer.locations = locations
        gradientLayer.frame = bounds ?? self.bounds
        gradientLayer.cornerRadius = cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
