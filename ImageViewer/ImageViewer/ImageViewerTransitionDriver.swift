//
//  ImageViewerTransitionDriver.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/05.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

class ImageViewerTransitionDriver: NSObject {

    var sourceView: UIView?

    var targetView: UIView?

    private let transitionContext: UIViewControllerContextTransitioning

    private let isPresenting: Bool

    private var panGestureRecognizer: UIPanGestureRecognizer?

    private(set) var transitionAnimator: UIViewPropertyAnimator!

    private var middleViewAnimator: UIViewPropertyAnimator!

    private var middleView: UIView!

    private var startLocation: CGPoint?

    private var currentLocation: CGPoint?

    private var containerView: UIView {
        return transitionContext.containerView
    }

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingPramaters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        // duration is not used when using UISpringTimingParameters, so set it to 0.0
        return UIViewPropertyAnimator(duration: 0.0, timingParameters: timingPramaters)
    }

    static func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return ImageViewerTransitionAnimator.animationDuration()
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool) {
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        super.init()
        initMiddleView()
        initMiddleViewAnimator()
        initTransitionAnimator()
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool, panGestureRecognizer: UIPanGestureRecognizer) {
        self.panGestureRecognizer = panGestureRecognizer
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        super.init()
        initMiddleView()
        initMiddleViewAnimator()
        initTransitionAnimator()
        self.panGestureRecognizer?.addTarget(self, action: #selector(updateInteraction(_:)))
    }

    private func initTransitionAnimator() {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)

        if isPresenting, let toView = toView {
            containerView.addSubview(toView)
        }

        let viewToTempHide = isPresenting ? toView : transitionContext.view(forKey: .from)
        viewToTempHide?.isHidden = true

        let animator = ImageViewerTransitionDriver.propertyAnimator()
        animator.addAnimations { }
        animator.addCompletion { [weak self] position in
            viewToTempHide?.isHidden = false
            let success = position == .end
            print(success)
            self?.transitionContext.completeTransition(success)
        }
        transitionAnimator = animator
    }

    private func initMiddleView() {
        if isPresenting {
            middleView = transitionContext.view(forKey: .to)!.snapshotView(afterScreenUpdates: true)
        } else {
            let fromView = transitionContext.view(forKey: .from)!
            let transitionView = sourceView ?? fromView
            let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: fromView) ?? fromView.bounds
            middleView = fromView.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: true, withCapInsets: .zero)
            middleView.frame = snapshotFrame
        }
    }

    private func initMiddleViewAnimator() {
        let animator = ImageViewerTransitionAnimator.propertyAnimator()
        middleView.frame = middleViewStartFrame()
        animator.addAnimations { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.middleView.frame = strongSelf.middleViewTargetFrame()
        }
        middleViewAnimator = animator
    }

    func animate() {
        UIView.animate(withDuration: 2.0) { [weak self] in
            self?.transitionAnimator.startAnimation()
//            self?.middleViewAnimator.startAnimation()
        }
    }

    private func middleViewStartFrame() -> CGRect {
        guard let sourceView = sourceView ?? transitionContext.view(forKey: .from) else {
            return .zero
        }

        if isPresenting {
            var frame: CGRect = .zero
            frame.size = CGSize(width: sourceView.bounds.width, height: sourceView.bounds.height)
            let center = sourceView.superview!.convert(sourceView.center, to: transitionContext.containerView)
            frame.origin = CGPoint(x: center.x - (frame.size.width / 2), y: center.y - (frame.size.height / 2))
            return frame
        } else {
            return sourceView.frame
        }
    }

    private func middleViewTargetFrame() -> CGRect {
        guard let targetView = targetView ?? transitionContext.view(forKey: .to) else {
            return .zero
        }

        if isPresenting {
            return targetView.frame
        } else {
            var frame: CGRect = .zero
            frame.size = CGSize(width: targetView.bounds.width, height: targetView.bounds.height)
            let center = targetView.superview!.convert(targetView.center, to: transitionContext.containerView)
            frame.origin = CGPoint(x: center.x - (frame.size.width / 2), y: center.y - (frame.size.height / 2))
            return frame
        }
    }
}

// MARK: - Interactive transition

extension ImageViewerTransitionDriver {

    @objc private func updateInteraction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let percentage = calculateProgress(translation)
            transitionAnimator.fractionComplete = percentage
            transitionContext.updateInteractiveTransition(percentage)
            //            updateMiddleView(translation)
            sender.setTranslation(.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            endInteraction()
        default:
            break
        }
    }

    private func calculateProgress(_ location: CGPoint) -> CGFloat {
        if startLocation == nil {
            startLocation = location
        }
        let oldLocation = currentLocation ?? .zero
        let newLocation = CGPoint(x: oldLocation.x + location.x, y: oldLocation.y + location.y)
        currentLocation = newLocation
        let verticalDistance = newLocation.y - startLocation!.y
        let progress = abs(verticalDistance / transitionContext.containerView.bounds.height)
        return progress
    }

    func endInteraction() {
        guard transitionContext.isInteractive else {
            return
        }

        let position = completionPosition()
        if position == .end {
            transitionContext.finishInteractiveTransition()
        } else {
            transitionContext.cancelInteractiveTransition()
        }

        animate(position)
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        if transitionAnimator.fractionComplete >= 0.5 {
            return .end
        } else {
            return .start
        }
    }

    func animate(_ toPosition: UIViewAnimatingPosition) {
        // TODO: pass velocity
        //        let itemFrameAnimator = ImageViewerTransitionDriver.propertyAnimator()
        //        itemFrameAnimator.addAnimations { [weak self] in
        //            self?.transitionView?.transform = (toPosition == .start ? self?.startTransform : self?.targetTransform) ?? .identity
        //        }
        //
        //        itemFrameAnimator.startAnimation()
        //        self.itemFrameAnimator = itemFrameAnimator

        transitionAnimator.isReversed = (toPosition == .start)

        if transitionAnimator.state == .inactive {
            transitionAnimator.startAnimation()
        } else {
            //            let durationFactor = CGFloat(itemFrameAnimator.duration / transitionAnimator.duration)
            let durationFactor = transitionAnimator.duration * Double(1 - transitionAnimator.fractionComplete)
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: CGFloat(durationFactor))
        }
    }

    //    private func updateMiddleView(_ translation: CGPoint) {
    //        let currentCenter = animator.middleView.center
    //        animator.middleView.center = CGPoint(x: currentCenter.x + translation.x, y: currentCenter.y + translation.y)
    //        let progress = transitionAnimator.fractionComplete
    //        let targetScale = animator.middleViewTargetTransform(transitionContext, middleView: animator.middleView)
    //        animator.middleView.transform = CGAffineTransform(scaleX: targetScale.tx * progress, y: targetScale.ty * progress)
    //    }
}
