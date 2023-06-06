//
//  RecordButton.swift
//  MRAudioRecorder
//
//  Created by Marco Ricca on 13/03/23.
//

import UIKit

/// Interface that defines the RecordButton delegate functions
protocol RecordButtonDelegate: AnyObject {
    /// Action started when the view (red button) is tapped
    func tapButton(isRecording: Bool)
}

/// Class for creating a view that represents the typical iOS red recording button
class RecordButton: UIView {
    private var isRecording = false
    private var roundView: UIView?
    private var squareSide: CGFloat?
    private let externalCircleFactor: CGFloat = 0.1
    private let roundViewSideFactor: CGFloat = 0.8

    weak var delegate: RecordButtonDelegate?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        setupRecordButtonView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        setupRecordButtonView()
    }
    
    override open func prepareForInterfaceBuilder() {
        backgroundColor = UIColor.clear
        setupRecordButtonView()
    }
    
    // MARK: - Public functions
    
    /// Public function to call when any errors occours and 'isRecording' variable is true
    public func endRecording() {
        roundView?.layer.add(recordButtonAnimation(), forKey: "")
        isRecording = false
    }

    // MARK: - Private functions
    
    /// Sets all necessary customizations for all UI elements present in this View
    private func setupRecordButtonView() {
        drawExternalCircle()
        drawRoundedButton()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedView)))
    }
    
    /// Adds a sub layer for showing the external white circle
    private func drawExternalCircle() {
        let layer = CAShapeLayer()
        let radius = min(bounds.width, bounds.height) / 2
        let lineWidth = externalCircleFactor * radius
        layer.path = UIBezierPath(arcCenter: CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2), radius: radius - lineWidth / 2, startAngle: 0, endAngle: 2 * CGFloat(Float.pi), clockwise: true).cgPath
        layer.lineWidth = lineWidth
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.gray.cgColor
        layer.opacity = 1

        self.layer.addSublayer(layer)
    }

    /// Customizes the view for visualizing the internal red circle
    private func drawRoundedButton() {
        squareSide = roundViewSideFactor * min(bounds.width, bounds.height)

        roundView = UIView(frame: CGRect(x: frame.size.width / 2 - squareSide! / 2, y: frame.size.height / 2 - squareSide! / 2, width: squareSide!, height: squareSide!))
        roundView?.backgroundColor = UIColor.red
        roundView?.layer.cornerRadius = squareSide! / 2

        addSubview(roundView!)
    }    
    
    /// Action started when the view (red button) is tapped
    /// The view changes from a red circle to a red square and it transfers the control to the delegate
    @objc private func tappedView() {
        roundView?.layer.add(recordButtonAnimation(), forKey: "")
        
        isRecording = !isRecording
        delegate?.tapButton(isRecording: isRecording)
    }
    
    /// Changes the view from a red circle to a red square and viceversa
    /// - Returns: the animation for view layer
    private func recordButtonAnimation() -> CAAnimationGroup {
        let transformToStopButton = CABasicAnimation(keyPath: "cornerRadius")

        transformToStopButton.fromValue = !isRecording ? squareSide! / 2 : 10
        transformToStopButton.toValue = !isRecording ? 10 : squareSide! / 2

        let toSmallCircle = CABasicAnimation(keyPath: "transform.scale")

        toSmallCircle.fromValue = !isRecording ? 1 : 0.65
        toSmallCircle.toValue = !isRecording ? 0.65 : 1

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [transformToStopButton, toSmallCircle]
        animationGroup.duration = 0.25
        animationGroup.fillMode = .both
        animationGroup.isRemovedOnCompletion = false

        return animationGroup
    }
}
