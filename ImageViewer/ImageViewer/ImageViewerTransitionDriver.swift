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

    private var middleViewAnimator: UIViewPropertyAnimator {
        return createMiddleViewAnimator()
    }

    private var _middleView: UIView?

    private var middleView: UIView {
        let view = _middleView ?? createMiddleView()
        _middleView = view
        return view
    }

    private var viewToTempHide: UIView? {
        return isPresenting ? transitionContext.view(forKey: .to) : transitionContext.view(forKey: .from)
    }

    private var startLocation: CGPoint?

    private var currentLocation: CGPoint?

    private var containerView: UIView {
        return transitionContext.containerView
    }

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        // duration is not used when using UISpringTimingParameters, so set it to 0.0
//        let timingParameters = UICubicTimingParameters(animationCurve: .easeOut)
        return UIViewPropertyAnimator(duration: 2.0, timingParameters: timingParameters)
    }

    static func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return ImageViewerTransitionAnimator.animationDuration()
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool) {
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        super.init()
        initTransitionAnimator()
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool, panGestureRecognizer: UIPanGestureRecognizer) {
        self.panGestureRecognizer = panGestureRecognizer
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        super.init()
        initTransitionAnimator()
        self.panGestureRecognizer?.addTarget(self, action: #selector(updateInteraction(_:)))
    }

    private func prepareContainerView() {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)

        if isPresenting, let toView = toView {
            containerView.addSubview(dimmingView)
            containerView.addSubview(toView)
        } else {
            containerView.addSubview(dimmingView)
        }

        containerView.addSubview(middleView)
        let startFrame = middleViewStartFrame()
        middleView.frame = startFrame
        viewToTempHide?.isHidden = true

        dimmingView.frame = containerView.bounds
        dimmingView.alpha = isPresenting ? 0.0 : 1.0
    }

    private func tearDown() {
        viewToTempHide?.isHidden = false
        _middleView?.removeFromSuperview()
        _middleView = nil
        dimmingView.removeFromSuperview()
    }

    private func initTransitionAnimator() {
        let animator = ImageViewerTransitionDriver.propertyAnimator()
        animator.addAnimations { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dimmingView.alpha = strongSelf.isPresenting ? 1.0 : 0.0
        }
        animator.addCompletion { [weak self] position in
            self?.tearDown()
            let success = position == .end
            self?.transitionContext.completeTransition(success)
        }
        transitionAnimator = animator
    }

    private func createMiddleView() -> UIView {
        if isPresenting {
            return transitionContext.view(forKey: .to)!.snapshotView(afterScreenUpdates: true)!
        } else {
            let fromView = transitionContext.view(forKey: .from)!
            let transitionView = sourceView ?? fromView
            let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: fromView) ?? fromView.bounds
            let view = fromView.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: false, withCapInsets: .zero)
            view?.frame = snapshotFrame
            return view!
        }
    }

    private func createMiddleViewAnimator() -> UIViewPropertyAnimator {
        let animator = ImageViewerTransitionAnimator.propertyAnimator()
        let targetFrame = middleViewTargetFrame()
        animator.addAnimations { [weak self] in
            self?.middleView.frame = targetFrame
        }
        animator.addCompletion { [weak self] _ in
            self?.middleView.removeFromSuperview()
            self?._middleView = nil
        }
        return animator
    }

    func animate() {
        prepareContainerView()
        transitionAnimator.startAnimation()
        middleViewAnimator.startAnimation()
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
            return sourceView.superview!.convert(sourceView.frame, to: containerView)
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
            if _middleView == nil {
                prepareContainerView()
            }

            let translation = sender.translation(in: transitionContext.containerView)
            let percentage = calculateProgress(translation)
            transitionAnimator.fractionComplete = percentage
            transitionContext.updateInteractiveTransition(percentage)
            updateMiddleView(translation)
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
        let progress = abs(verticalDistance / (transitionContext.containerView.bounds.height / 2))
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
        if transitionAnimator.fractionComplete >= 0.8 {
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

        private func updateMiddleView(_ translation: CGPoint) {
            let currentCenter = middleView.center
            let middleCenter = CGPoint(x: currentCenter.x + translation.x, y: currentCenter.y + translation.y)
            let progress = transitionAnimator.fractionComplete
            let startSize = middleViewStartFrame().size
            let targetSize = middleViewTargetFrame().size
            let diffSizeWidth = startSize.width - targetSize.width
            let diffSizeHeight = startSize.height - targetSize.height
            let progressDiffWidth = diffSizeWidth * progress
            let progressDiffHeight = diffSizeHeight * progress
            let midSize = CGSize(width: startSize.width - progressDiffWidth, height: startSize.height - progressDiffHeight)
            let middleFrame = CGRect(x: middleCenter.x - (midSize.width / 2), y: middleCenter.y - (midSize.height / 2), width: midSize.width, height: midSize.height)
            middleView.frame = middleFrame
        }
}
