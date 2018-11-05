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

    private var animator: ImageViewerTransitionAnimator!

    private let panGestureRecognizer: UIPanGestureRecognizer

    private(set) var transitionDriver: ImageViewerTransitionDriver?

    init(_ panGestureRecognizer: UIPanGestureRecognizer) {
        self.panGestureRecognizer = panGestureRecognizer
    }

    func setAnimator(_ animator: ImageViewerTransitionAnimator) {
        self.animator = animator
    }

    func tearDown() {
        initiallyInteractive = false
        transitionDriver = nil
    }
}

extension ImageViewerInteractiveTransitionController: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        transitionDriver = ImageViewerTransitionDriver(transitionContext, animator: animator, panGestureRecognizer: panGestureRecognizer)
    }

    var wantsInteractiveStart: Bool {
        return initiallyInteractive
    }
}
