//
//  ImageViewerSwipeDownTracker.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/05.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

class ImageViewerSwipeDownTracker: NSObject {

    private var initialBounds: CGRect = .zero

    private var initialCenter: CGPoint = .zero

    private var initialGestureLocation: CGPoint = .zero

    private var trackedBounds: CGRect = .zero

    private var trackedCenter: CGPoint = .zero

    private var trackedTransform: CGAffineTransform = .identity

    private var trackedVelocity: CGPoint = .zero

    var dismissalProgress: CGFloat {
        return 0.0
    }

    var finalAnimationDuration: CGFloat {
        return 0.0
    }

    var finalAnimationSpringDamping: CGFloat {
        return 0.0
    }

    var shouldFinishDismissal: Bool {
        return false
    }

    func startTracking(_ center: CGPoint, bounds: CGRect, initialGestureLocations: CGPoint) {
    }

    func trackGesture(_ translation: CGPoint, velocity: CGPoint) {
    }
}
