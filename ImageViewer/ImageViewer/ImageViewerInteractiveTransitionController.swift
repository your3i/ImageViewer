//
//  ImageViewerInteractiveTransitionController.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/05.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

class ImageViewerInteractiveTransitionController: NSObject {

    var initiallyInteractive: Bool = false

    var isPresenting: Bool = true

    var sourceView: UIView?

    var targetView: UIView?

    var panGestureRecognizer: UIPanGestureRecognizer?

    private(set) var interactiveTransitionDriver: ImageViewerTransitionDriver?
}

extension ImageViewerInteractiveTransitionController: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return ImageViewerTransitionDriver.transitionDuration(using: nil)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let driver = ImageViewerTransitionDriver(transitionContext, isPresenting: isPresenting)
        interactiveTransitionDriver = driver
        driver.sourceView = sourceView
        driver.targetView = targetView
        driver.animate()
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        return interactiveTransitionDriver!.transitionAnimator
    }

    func animationEnded(_ transitionCompleted: Bool) {
        interactiveTransitionDriver = nil
        initiallyInteractive = false
        isPresenting = true
        sourceView = nil
        targetView = nil
    }
}

extension ImageViewerInteractiveTransitionController: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        interactiveTransitionDriver = ImageViewerTransitionDriver(transitionContext, isPresenting: isPresenting, panGestureRecognizer: panGestureRecognizer!)
        interactiveTransitionDriver?.sourceView = sourceView
        interactiveTransitionDriver?.targetView = targetView
    }

    var wantsInteractiveStart: Bool {
        return initiallyInteractive
    }
}
