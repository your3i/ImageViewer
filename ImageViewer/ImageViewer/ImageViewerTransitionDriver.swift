//
//  ImageViewerTransitionDriver.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/05.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

class ImageViewerTransitionDriver: NSObject {

    private let transitionContext: UIViewControllerContextTransitioning

    private let panGestureRecognizer: UIPanGestureRecognizer

    private var transitionAnimator: UIViewPropertyAnimator!

    private var itemFrameAnimator: UIViewPropertyAnimator?

    static func animationDuration() -> TimeInterval {
        return propertyAnimator().duration
    }

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingPramaters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        return UIViewPropertyAnimator(duration: 2.0, timingParameters: timingPramaters)
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, panGestureRecognizer: UIPanGestureRecognizer) {
        self.transitionContext = transitionContext
        self.panGestureRecognizer = panGestureRecognizer
//        setupTransitionAnimator({
//
//        }, transitionCompletion: { _ in
//
//        })
    }

    private func setupTransitionAnimator(_ transitionAnimations: @escaping ()->(), transitionCompletion: @escaping (UIViewAnimatingPosition)->()) {
        let transitionDuration = ImageViewerTransitionDriver.animationDuration()
        transitionAnimator = UIViewPropertyAnimator(duration: transitionDuration, curve: UIView.AnimationCurve.easeOut, animations: transitionAnimations)
        transitionAnimator.addCompletion { [weak self] position in
            transitionCompletion(position)

            let completed = (position == .end)
            self?.transitionContext.completeTransition(completed)
        }
    }

    func updateInteraction(_ fromGesture: UIPanGestureRecognizer) {
        guard transitionContext.isInteractive else {
            return
        }
        switch fromGesture.state {
        case .began, .changed:
            let translation = fromGesture.translation(in: transitionContext.containerView)
//            let percentComplete = transitionAnimator.fractionComplete +
        // TODO: percentage calculation

            let percentComplete: CGFloat = 0.0
            transitionAnimator.fractionComplete = percentComplete
            transitionContext.updateInteractiveTransition(percentComplete)
            fromGesture.setTranslation(.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            endInteraction()
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

    func animate(_ toPosition: UIViewAnimatingPosition) {
        // TODO: pass velocity
        let itemFrameAnimator = ImageViewerTransitionDriver.propertyAnimator()
        itemFrameAnimator.addAnimations {
            // itemframe = initialFrame or targetFrame
        }

        itemFrameAnimator.startAnimation()
        self.itemFrameAnimator = itemFrameAnimator

        transitionAnimator.isReversed = (toPosition == .start)

        if transitionAnimator.state == .inactive {
            transitionAnimator.startAnimation()
        } else {
            let durationFactor = CGFloat(itemFrameAnimator.duration / transitionAnimator.duration)
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }

    func pauseAnimation() {
        itemFrameAnimator?.stopAnimation(true)
        transitionAnimator.pauseAnimation()
        transitionContext.pauseInteractiveTransition()
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        return .end
    }
}
