//
//  ShutterButton.swift
//  WeScan
//
//  Created by Boris Emorine on 2/26/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A simple button used for the shutter.
final class ShutterButton: UIControl {

    private let outerRingLayer = CAShapeLayer()
    private let innerCircleLayer = CAShapeLayer()
    private let cameraIconView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        imageView.image = UIImage(systemName: "camera.fill", withConfiguration: config)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let outerRingRatio: CGFloat = 0.80
    private let innerRingRatio: CGFloat = 0.75

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    override var isHighlighted: Bool {
        didSet {
            if oldValue != isHighlighted {
                animateInnerCircleLayer(forHighlightedState: isHighlighted)
            }
        }
    }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(outerRingLayer)
        layer.addSublayer(innerCircleLayer)
        addSubview(cameraIconView)
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraits.button
        impactFeedbackGenerator.prepare()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let iconSize = bounds.width * 0.4
        cameraIconView.frame = CGRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        outerRingLayer.frame = rect
        outerRingLayer.path = pathForOuterRing(inRect: rect).cgPath
        outerRingLayer.fillColor = UIColor.white.cgColor
        outerRingLayer.rasterizationScale = UIScreen.main.scale
        outerRingLayer.shouldRasterize = true
        
        innerCircleLayer.frame = rect
        innerCircleLayer.path = pathForInnerCircle(inRect: rect).cgPath
        innerCircleLayer.fillColor = UIColor(
            red: 10 / 255,
            green: 89 / 255,
            blue: 67 / 255,
            alpha: 1
        ).cgColor
        innerCircleLayer.rasterizationScale = UIScreen.main.scale
        innerCircleLayer.shouldRasterize = true
    }

    // MARK: - Animation

    private func animateInnerCircleLayer(forHighlightedState isHighlighted: Bool) {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        var values = [
            CATransform3DMakeScale(1.0, 1.0, 1.0),
            CATransform3DMakeScale(0.9, 0.9, 0.9),
            CATransform3DMakeScale(0.93, 0.93, 0.93),
            CATransform3DMakeScale(0.9, 0.9, 0.9)
        ]
        if isHighlighted == false {
            values = [CATransform3DMakeScale(0.9, 0.9, 0.9), CATransform3DMakeScale(1.0, 1.0, 1.0)]
        }
        animation.values = values
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.duration = isHighlighted ? 0.35 : 0.10

        innerCircleLayer.add(animation, forKey: "transform")
        impactFeedbackGenerator.impactOccurred()
    }

    // MARK: - Paths

    private func pathForOuterRing(inRect rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath(ovalIn: rect)

        let innerRect = rect.scaleAndCenter(withRatio: outerRingRatio)
        let innerPath = UIBezierPath(ovalIn: innerRect).reversing()

        path.append(innerPath)

        return path
    }

    private func pathForInnerCircle(inRect rect: CGRect) -> UIBezierPath {
        let rect = rect.scaleAndCenter(withRatio: innerRingRatio)
        let path = UIBezierPath(ovalIn: rect)

        return path
    }

}
