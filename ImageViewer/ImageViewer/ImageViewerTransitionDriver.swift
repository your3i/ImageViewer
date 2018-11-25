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

    private var containerView: UIView {
        return transitionContext.containerView
    }

    private var dimmingView: UIView!

    private var transitionView: UIView!

    private var viewToTempHide: UIView? {
        return isPresenting ? transitionContext.view(forKey: .to) : transitionContext.view(forKey: .from)
    }

    private var panGestureRecognizer: UIPanGestureRecognizer?

    private(set) var interactiveAnimator: UIViewPropertyAnimator!

    private var startLocation: CGPoint?

    private var currentLocation: CGPoint?

    private var tracker: ImageViewerPanTracker!

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        // duration is not used when using UISpringTimingParameters, so set it to 0.0
        return UIViewPropertyAnimator(duration: 0.0, timingParameters: timingParameters)
    }

    static func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return propertyAnimator().duration
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool, sourceView: UIView? = nil, targetView: UIView?) {
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        self.sourceView = sourceView
        self.targetView = targetView
        super.init()
        prepare()
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, isPresenting: Bool, panGestureRecognizer: UIPanGestureRecognizer, sourceView: UIView? = nil, targetView: UIView?) {
        self.panGestureRecognizer = panGestureRecognizer
        self.transitionContext = transitionContext
        self.isPresenting = isPresenting
        self.sourceView = sourceView
        self.targetView = targetView
        super.init()
        prepare()
        initInteractiveAnimator()
        self.panGestureRecognizer?.addTarget(self, action: #selector(updateInteraction(_:)))
    }

    private func prepare() {
        dimmingView = UIView()
        dimmingView.backgroundColor = .black
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)

        transitionView = {
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
        }()
        containerView.addSubview(transitionView)

        if isPresenting, let toView = transitionContext.view(forKey: .to) {
            containerView.addSubview(toView)
        }

        let startFrame: CGRect = {
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
        }()

        let targetFrame: CGRect = {
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
        }()

        tracker = ImageViewerPanTracker(startFrame: startFrame, targetFrame: targetFrame)
        tracker.dismissalProgress = 0.7
        transitionView.frame = startFrame
    }

    func startAnimation() {
        dimmingView.alpha = isPresenting ? 0.0 : 1.0
        viewToTempHide?.isHidden = true

        let animator = ImageViewerTransitionDriver.propertyAnimator()
        animator.addAnimations { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dimmingView.alpha = strongSelf.isPresenting ? 1.0 : 0.0
            strongSelf.transitionView.frame = strongSelf.tracker.targetFrame
        }
        animator.addCompletion { [weak self] position in
            self?.tearDown()
            let success = position == .end
            self?.transitionContext.completeTransition(success)
        }
        animator.startAnimation()
    }

    private func tearDown() {
        viewToTempHide?.isHidden = false
        transitionView.removeFromSuperview()
        dimmingView.removeFromSuperview()
    }
}

// MARK: - Interactive transition

extension ImageViewerTransitionDriver {

    private func initInteractiveAnimator() {
        dimmingView.alpha = isPresenting ? 0.0 : 1.0
        viewToTempHide?.isHidden = true

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
        interactiveAnimator = animator
    }

    @objc private func updateInteraction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            let location = sender.translation(in: containerView)
            let velocity = sender.velocity(in: containerView)
            tracker.update(location, velocity: velocity, center: transitionView.center)
            let progress = tracker.progress
            interactiveAnimator.fractionComplete = progress
            transitionContext.updateInteractiveTransition(progress)
            if let shouldCurrentFrame = tracker.shouldCurrentFrame {
                transitionView.frame = shouldCurrentFrame
            }
            sender.setTranslation(.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            endInteraction()
            tracker.endTracking()
        default:
            break
        }
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
        if tracker.shouldFinishDismissal {
            return .end
        } else {
            return .start
        }
    }

    func animate(_ toPosition: UIViewAnimatingPosition) {
        let animator = ImageViewerTransitionDriver.propertyAnimator()
        animator.addAnimations { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.transitionView.frame = (toPosition == .start ? strongSelf.tracker.startFrame : strongSelf.tracker.targetFrame)
        }

        animator.startAnimation()

        interactiveAnimator.isReversed = (toPosition == .start)

        if interactiveAnimator.state == .inactive {
            interactiveAnimator.startAnimation()
        } else {
            let durationFactor = CGFloat(animator.duration / interactiveAnimator.duration)
            interactiveAnimator.continueAnimation(withTimingParameters: nil, durationFactor: CGFloat(durationFactor))
        }
    }
}
