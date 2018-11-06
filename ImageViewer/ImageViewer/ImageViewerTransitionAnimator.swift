//
//  ImageViewerTransitionAnimator.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

final class ImageViewerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var sourceView: UIView?

    var destinationView: UIView?

    private(set) var interactiveAnimator: UIViewPropertyAnimator!

    private(set) var middleViewAnimator: UIViewPropertyAnimator!

    private(set) var middleView: UIView!

    private var isPresenting: Bool = true

    private override init() { }

    static func instanceForPresent() -> ImageViewerTransitionAnimator {
        let animator = ImageViewerTransitionAnimator()
        animator.isPresenting = true
        return animator
    }

    static func instanceForDismiss() -> ImageViewerTransitionAnimator {
        let animator = ImageViewerTransitionAnimator()
        animator.isPresenting = false
        return animator
    }

    static func animationDuration() -> TimeInterval {
        return propertyAnimator().duration
    }

    static func propertyAnimator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingPramaters = UISpringTimingParameters(mass: 2.5, stiffness: 1400, damping: 95, initialVelocity: initialVelocity)
        // duration is not used when using UISpringTimingParameters, so set it to 0.0
        return UIViewPropertyAnimator(duration: 0.0, timingParameters: timingPramaters)
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return ImageViewerTransitionAnimator.animationDuration()
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated else {
            transitionContext.completeTransition(true)
            return
        }

        let animator = createTransitionAnimator(transitionContext)
        UIView.animate(withDuration: transitionDuration(using: transitionContext)) {
            animator.startAnimation()
        }

        middleViewAnimator = createMiddleViewAnimator(transitionContext, middleView: middleView)
        middleViewAnimator?.startAnimation()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        if interactiveAnimator == nil {
            interactiveAnimator = createTransitionAnimator(transitionContext)
        }
        return interactiveAnimator
    }

    private func createTransitionAnimator(_ transitionContext: UIViewControllerContextTransitioning) -> UIViewPropertyAnimator {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)

        createMiddleViewIfNeeded(transitionContext)

        if isPresenting, let toView = toView {
            containerView.addSubview(toView)
        }
        if let middleView = middleView {
            containerView.addSubview(middleView)
        }

        let viewToTempHide = isPresenting ? toView : transitionContext.view(forKey: .from)
        viewToTempHide?.isHidden = true
        middleView?.alpha = isPresenting ? 0.8 : 1.0

        let duration = transitionDuration(using: transitionContext)
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.middleView?.alpha = strongSelf.isPresenting ? 1.0 : 0.8
        })
        animator.addCompletion { [weak self] position in
            viewToTempHide?.isHidden = false
            self?.middleView?.removeFromSuperview()
            transitionContext.completeTransition(position == .end)
        }
        return animator
    }

    private func createMiddleViewAnimator(_ transitionContext: UIViewControllerContextTransitioning, middleView: UIView) -> UIViewPropertyAnimator? {
        let animator = ImageViewerTransitionAnimator.propertyAnimator()
        middleView.transform = middleViewStartTransform(transitionContext, middleView: middleView)
        animator.addAnimations { [weak self] in
            guard let strongSelf = self else {
                return
            }
            middleView.transform = strongSelf.middleViewTargetTransform(transitionContext, middleView: middleView)
        }
        return animator
    }

    private func createMiddleViewIfNeeded(_ transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            middleView = transitionContext.view(forKey: .to)!.snapshotView(afterScreenUpdates: true)
        } else {
            let fromView = transitionContext.view(forKey: .from)!
            let transitionView = sourceView ?? fromView
            let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: fromView) ?? fromView.bounds
            middleView = fromView.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: true, withCapInsets: .zero)
            middleView?.frame = snapshotFrame
        }
    }

    func middleViewStartTransform(_ transitionContext: UIViewControllerContextTransitioning, middleView: UIView) -> CGAffineTransform {
        if isPresenting {
            guard let fromView = sourceView ?? transitionContext.view(forKey: .from) else {
                return .identity
            }

            let scaleTransform = CGAffineTransform(scaleX: fromView.bounds.width / middleView.bounds.width, y: fromView.bounds.height / middleView.bounds.height)
            var translationTransfrom = CGAffineTransform(translationX: 0.0, y: 0.0)
            if let toCenter = fromView.superview?.convert(fromView.center, to: transitionContext.containerView) {
                translationTransfrom = CGAffineTransform(translationX: toCenter.x - middleView.center.x, y: toCenter.y - middleView.center.y)
            }
            return scaleTransform.concatenating(translationTransfrom)
        } else {
            return .identity
        }
    }

    func middleViewTargetTransform(_ transitionContext: UIViewControllerContextTransitioning, middleView: UIView) -> CGAffineTransform {
        if isPresenting {
            return .identity
        } else {
            guard let toView = destinationView ?? transitionContext.view(forKey: .to) else {
                return .identity
            }

            let scaleTransform = CGAffineTransform(scaleX: toView.bounds.width / middleView.bounds.width, y: toView.bounds.height / middleView.bounds.height)

            var translationTransfrom = CGAffineTransform(translationX: 0.0, y: 0.0)
            if let toCenter = toView.superview?.convert(toView.center, to: transitionContext.containerView) {
                translationTransfrom = CGAffineTransform(translationX: toCenter.x - middleView.center.x, y: toCenter.y - middleView.center.y)
            }
            return scaleTransform.concatenating(translationTransfrom)
        }
    }
}
