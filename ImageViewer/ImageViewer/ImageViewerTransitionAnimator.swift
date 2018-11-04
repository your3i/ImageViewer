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

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated else {
            transitionContext.completeTransition(true)
            return
        }

        if isPresenting {
            presentingTransition(transitionContext)
        } else {
            dismissingTransition(transitionContext)
        }
    }

    private func presentingTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let complete = {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        guard let toView = transitionContext.view(forKey: .to), let toViewSnapshot = toView.snapshotView(afterScreenUpdates: true) else {
            complete()
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
        toView.isHidden = true
        containerView.addSubview(toViewSnapshot)

        if let fromView = sourceView ?? transitionContext.view(forKey: .from) {
            let scaleWidth = fromView.bounds.width / toViewSnapshot.bounds.width
            let scaleHeight = fromView.bounds.height / toViewSnapshot.bounds.height
            toViewSnapshot.transform = CGAffineTransform(scaleX: scaleWidth, y: scaleHeight)

            if let fromSuperView = fromView.superview {
                toViewSnapshot.center = fromSuperView.convert(fromView.center, to: containerView)
            }
        }

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toViewSnapshot.transform = .identity
            toViewSnapshot.center = toView.center
        }, completion: { _ in
            toViewSnapshot.removeFromSuperview()
            toView.isHidden = false
            complete()
        })
    }

    private func dismissingTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let complete = {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        guard let fromView = transitionContext.view(forKey: .from) else {
            complete()
            return
        }

        let containerView = transitionContext.containerView

        let transitionView = sourceView ?? fromView
        guard let snapshot = transitionView.snapshotView(afterScreenUpdates: true), let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: containerView) else {
            complete()
            return
        }
        snapshot.frame = snapshotFrame
        containerView.addSubview(snapshot)
        fromView.isHidden = true

        var toTransform: CGAffineTransform?
        var toCenter: CGPoint?
        if let toView = destinationView ?? transitionContext.view(forKey: .to) {
            let scaleWidth = toView.bounds.width / snapshot.bounds.width
            let scaleHeight = toView.bounds.height / snapshot.bounds.height
            toTransform = CGAffineTransform(scaleX: scaleWidth, y: scaleHeight)
            toCenter = toView.superview?.convert(toView.center, to: containerView)
        }

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            if let transform = toTransform {
                snapshot.transform = transform
            }
            if let toCenter = toCenter {
                snapshot.center = toCenter
            }
        }, completion: { _ in
            snapshot.removeFromSuperview()
            complete()
        })
    }
}
