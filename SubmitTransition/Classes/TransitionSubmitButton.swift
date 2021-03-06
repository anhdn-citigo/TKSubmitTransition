import Foundation
import UIKit

@IBDesignable
open class TKTransitionSubmitButton : UIButton, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    lazy var spiner: SpinerLayer? = {
        if #available(iOS 10, *) {
            let s = SpinerLayer(frame: self.frame)
            return s
        }
        return nil
    }()
    
    @IBInspectable open var spinnerColor: UIColor = UIColor.white {
        didSet {
            spiner?.spinnerColor = spinnerColor
        }
    }
    
    open var didEndFinishAnimation : (()->())? = nil
    
    let springGoEase = CAMediaTimingFunction(controlPoints: 0.45, -0.36, 0.44, 0.92)
    let shrinkCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
    let expandCurve = CAMediaTimingFunction(controlPoints: 0.95, 0.02, 1, 0.05)
    let shrinkDuration: CFTimeInterval  = 0.1
    @IBInspectable open var normalCornerRadius:CGFloat = 0.0 {
        didSet {
            self.layer.cornerRadius = normalCornerRadius
        }
    }
    
    var cachedTitle: String?
    var isAnimating = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init!(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }
    
    func setup() {
        self.clipsToBounds = true
        spiner?.spinnerColor = spinnerColor
    }
    
    open func startLoadingAnimation() {
        guard let spiner = spiner else { return }
        self.isAnimating = true
        self.cachedTitle = title(for: UIControl.State())
        self.setTitle("", for: UIControl.State())
        self.layer.addSublayer(spiner)
        
        // Animate
        self.cornerRadius()
        self.shrink()
        _ = Timer.schedule(delay: self.shrinkDuration - 0.25) { timer in
            spiner.animation()
        }
    }
    
    open func startFinishAnimation(_ delay: TimeInterval, completion:(()->())?) {
        
        guard let spiner = spiner else {
            completion?()
            return }
        self.isAnimating = true
        _ = Timer.schedule(delay: delay) { timer in
            self.didEndFinishAnimation = completion
            self.expand()
            spiner.stopAnimation()
        }
    }
    
    open func animate(_ duration: TimeInterval, completion:(()->())?) {
        startLoadingAnimation()
        startFinishAnimation(duration, completion: completion)
    }
    
    open func setOriginalState() {
        
        guard let spiner = spiner else { return }
        self.returnToOriginalState()
        spiner.stopAnimation()
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let a = anim as! CABasicAnimation
        if a.keyPath == "transform.scale" {
            didEndFinishAnimation?()
            _ = Timer.schedule(delay: 1) { timer in
                self.returnToOriginalState()
            }
        }
    }
    
    open func returnToOriginalState() {
        
        guard let spiner = spiner else { return }
        spiner.removeFromSuperlayer()
        self.layer.removeAllAnimations()
        self.setTitle(self.cachedTitle, for: UIControl.State())
        spiner.stopAnimation()
        self.isAnimating = false
    }
    
    func cornerRadius() {
        let cornerRadiusAnim = CABasicAnimation(keyPath: "cornerRadius")
        // cornerRadiusAnim.fromValue = frame.width
        cornerRadiusAnim.toValue = frame.height/2
        cornerRadiusAnim.duration = shrinkDuration
        cornerRadiusAnim.timingFunction = shrinkCurve
        cornerRadiusAnim.fillMode = CAMediaTimingFillMode.forwards
        cornerRadiusAnim.isRemovedOnCompletion = false
        layer.add(cornerRadiusAnim, forKey: cornerRadiusAnim.keyPath)
    }
    
    func shrink() {
        let shrinkAnim = CABasicAnimation(keyPath: "bounds.size.width")
        shrinkAnim.beginTime = CACurrentMediaTime() + 0.1
        shrinkAnim.fromValue = frame.width
        shrinkAnim.toValue = frame.height
        shrinkAnim.duration = shrinkDuration
        shrinkAnim.timingFunction = shrinkCurve
        shrinkAnim.fillMode = CAMediaTimingFillMode.forwards
        shrinkAnim.isRemovedOnCompletion = false
        layer.add(shrinkAnim, forKey: shrinkAnim.keyPath)
    }
    
    func expand() {
        let expandAnim = CABasicAnimation(keyPath: "transform.scale")
        expandAnim.fromValue = 1.0
        expandAnim.toValue = 26.0
        expandAnim.timingFunction = expandCurve
        expandAnim.duration = 0.3
        expandAnim.delegate = self
        expandAnim.fillMode = CAMediaTimingFillMode.forwards
        expandAnim.isRemovedOnCompletion = false
        layer.add(expandAnim, forKey: expandAnim.keyPath)
    }
    
}
