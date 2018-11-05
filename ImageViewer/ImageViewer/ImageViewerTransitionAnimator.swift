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

        guard let fromView = sourceView ?? transitionContext.view(forKey: .from) else {
            complete()
            return
        }

        let scaleTransform = CGAffineTransform(scaleX: fromView.bounds.width / toViewSnapshot.bounds.width, y: fromView.bounds.height / toViewSnapshot.bounds.height)
        var translationTransfrom = CGAffineTransform(translationX: 0.0, y: 0.0)
        if let toCenter = fromView.superview?.convert(fromView.center, to: containerView) {
            translationTransfrom = CGAffineTransform(translationX: toCenter.x - toViewSnapshot.center.x, y: toCenter.y - toViewSnapshot.center.y)
        }
        toViewSnapshot.transform = scaleTransform.concatenating(translationTransfrom)
        toViewSnapshot.alpha = 0.1

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toViewSnapshot.transform = .identity
            toViewSnapshot.alpha = 1.0
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

        guard
            let fromView = transitionContext.view(forKey: .from),
            let transitionView = sourceView ?? transitionContext.view(forKey: .from),
            let snapshotFrame = transitionView.superview?.convert(transitionView.frame, to: fromView),
            let snapshot = fromView.resizableSnapshotView(from: snapshotFrame, afterScreenUpdates: true, withCapInsets: .zero) else {
                complete()
                return
        }

        let containerView = transitionContext.containerView
        snapshot.frame = snapshotFrame
        containerView.addSubview(snapshot)
        fromView.isHidden = true

        guard let toView = destinationView ?? transitionContext.view(forKey: .to) else {
            complete()
            return
        }

        let scaleTransform = CGAffineTransform(scaleX: toView.bounds.width / snapshot.bounds.width, y: toView.bounds.height / snapshot.bounds.height)

        var translationTransfrom = CGAffineTransform(translationX: 0.0, y: 0.0)
        if let toCenter = toView.superview?.convert(toView.center, to: containerView) {
            translationTransfrom = CGAffineTransform(translationX: toCenter.x - snapshot.center.x, y: toCenter.y - snapshot.center.y)
        }

        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            snapshot.transform = scaleTransform.concatenating(translationTransfrom)
        }, completion: { _ in
            snapshot.removeFromSuperview()
            complete()
        })
    }
}
