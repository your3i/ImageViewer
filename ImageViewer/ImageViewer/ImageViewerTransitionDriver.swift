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

    private let panGestureRecognier: UIPanGestureRecognizer

    private let animator: ImageViewerTransitionAnimator

    private(set) var transitionAnimator: UIViewPropertyAnimator!

    private var itemFrameAnimator: UIViewPropertyAnimator?

    var transitionView: UIView? {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let transitionView = animator.sourceView ?? transitionContext.view(forKey: .from),
            let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: fromView),
            let snapshot = fromView.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: true, withCapInsets: .zero) else {
                return nil
        }
        snapshot.frame = snapshotFrame
        return snapshot
    }

    var startTransform: CGAffineTransform {
        return .identity
    }

    var targetTransform: CGAffineTransform {
        guard let transitionView = transitionView, let toView = animator.destinationView ?? transitionContext.view(forKey: .to) else {
            return .identity
        }

        let scaleTransform = CGAffineTransform(scaleX: toView.bounds.width / transitionView.bounds.width, y: toView.bounds.height / transitionView.bounds.height)

        var translationTransfrom = CGAffineTransform(translationX: 0.0, y: 0.0)
        if let toCenter = toView.superview?.convert(toView.center, to: transitionContext.containerView) {
            translationTransfrom = CGAffineTransform(translationX: toCenter.x - transitionView.center.x, y: toCenter.y - transitionView.center.y)
        }
        return scaleTransform.concatenating(translationTransfrom)
    }

    static func animationDuration() -> TimeInterval {
        return propertyAnimator().duration
    }

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingPramaters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        // duration is not used when using UISpringTimingParameters, so set it to 0.0
        return UIViewPropertyAnimator(duration: 0.0, timingParameters: timingPramaters)
    }

    init(_ transitionContext: UIViewControllerContextTransitioning, animator: ImageViewerTransitionAnimator, panGestureRecognizer: UIPanGestureRecognizer) {
        self.transitionContext = transitionContext
        self.panGestureRecognier = panGestureRecognizer
        self.animator = animator
        super.init()

        self.panGestureRecognier.addTarget(self, action: #selector(updateInteraction(_:)))
        setupTransitionAnimator({

        }, transitionCompletion: { _ in

        })
    }

    private func setupTransitionAnimator(_ transitionAnimations: @escaping ()->(), transitionCompletion: @escaping (UIViewAnimatingPosition)->()) {
        let transitionDuration = ImageViewerTransitionDriver.animationDuration()
        transitionAnimator = UIViewPropertyAnimator(duration: transitionDuration, curve: UIView.AnimationCurve.easeOut, animations: transitionAnimations)
        transitionAnimator.addCompletion { [weak self] position in
            transitionCompletion(position)
            let completed = (position == .end)
            self?.transitionContext.completeTransition(completed)
        }
        prepareInteraction()
    }

    @objc private func updateInteraction(_ fromGesture: UIPanGestureRecognizer) {
        switch fromGesture.state {
        case .began, .changed:
            let translation = fromGesture.translation(in: transitionContext.containerView)
            print(transitionAnimator.state == .inactive)
            transitionAnimator.fractionComplete = transitionAnimator.fractionComplete + translation.y
            print(transitionAnimator.state == .inactive)
            transitionContext.updateInteractiveTransition(transitionAnimator.fractionComplete + translation.y)
            updateInteractiveView(translation)
            fromGesture.setTranslation(.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            endInteraction()
        default:
            break
        }
    }

    func prepareInteraction() {
        guard let transitionView = transitionView, let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        let containerView = transitionContext.containerView
        containerView.addSubview(transitionView)
        fromView.isHidden = true
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
        print(transitionAnimator.fractionComplete)
        if transitionAnimator.fractionComplete >= 0.8 {
            return UIViewAnimatingPosition.end
        } else {
            return UIViewAnimatingPosition.start
        }
    }

    func animate(_ toPosition: UIViewAnimatingPosition) {
        // TODO: pass velocity
        let itemFrameAnimator = ImageViewerTransitionDriver.propertyAnimator()
        itemFrameAnimator.addAnimations { [weak self] in
            self?.transitionView?.transform = (toPosition == .start ? self?.startTransform : self?.targetTransform) ?? .identity
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

    private func updateInteractiveView(_ translation: CGPoint) {
        guard let transitionView = transitionView else {
            return
        }
        let newTransform = CGAffineTransform(translationX: translation.x, y: translation.y)
        print(newTransform)
        DispatchQueue.main.async {
            transitionView.transform = newTransform
        }
    }
}
