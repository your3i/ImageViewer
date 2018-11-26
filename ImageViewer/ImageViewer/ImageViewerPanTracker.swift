//
//  ImageViewerPanTracker.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/25.
//  Copyright © 2018 your3i. All rights reserved.
//

import Foundation
import UIKit

class ImageViewerPanTracker: NSObject {

    let startFrame: CGRect

    let targetFrame: CGRect

    private var startLocation: CGPoint?

    private var trackedLocation: CGPoint = .zero

    private var trackedVelocity: CGPoint = .zero

    private var trackedCenter: CGPoint = .zero

    private(set) var shouldCurrentFrame: CGRect?

    var progress: CGFloat {
        return calculateProgress()
    }

    var dismissalProgress: CGFloat = 1.0

    var shouldFinishDismissal: Bool {
        return (calculateProgress() >= dismissalProgress || abs(trackedVelocity.y) >= 3000.0)
    }

    init(startFrame: CGRect, targetFrame: CGRect) {
        self.startFrame = startFrame
        self.targetFrame = targetFrame
        self.shouldCurrentFrame = startFrame
    }

    func update(_ diffLocation: CGPoint, velocity: CGPoint, center: CGPoint) {
        trackedVelocity = velocity
        trackedCenter = center

        if startLocation == nil {
            startLocation = diffLocation
        }
        trackedLocation = CGPoint(x: trackedLocation.x + diffLocation.x, y: trackedLocation.y + diffLocation.y)
        let newCenter = calculateNewCenter(diffLocation)
        let newSize = calculateNewSize(progress)
        shouldCurrentFrame = CGRect(x: newCenter.x - (newSize.width / 2), y: newCenter.y - (newSize.height / 2), width: newSize.width, height: newSize.height)
    }

    func endTracking() {
        startLocation = nil
        trackedLocation = .zero
        trackedVelocity = .zero
        trackedCenter = .zero
        shouldCurrentFrame = nil
    }

    private func calculateProgress() -> CGFloat {
        guard let startLocation = startLocation else {
            return 0.0
        }
        let verticalDistance = trackedLocation.y - startLocation.y
        return abs(verticalDistance / (UIScreen.main.bounds.height / 2))
    }

    private func calculateNewCenter(_ diffLocation: CGPoint) -> CGPoint {
        return CGPoint(x: trackedCenter.x + diffLocation.x, y: trackedCenter.y + diffLocation.y)
    }

    private func calculateNewSize(_ progress: CGFloat) -> CGSize {
        let startSize = startFrame.size
        let targetSize = targetFrame.size
        let diffSizeWidth = startSize.width - targetSize.width
        let diffSizeHeight = startSize.height - targetSize.height
        let progressDiffWidth = diffSizeWidth * progress
        let progressDiffHeight = diffSizeHeight * progress
        return CGSize(width: startSize.width - progressDiffWidth, height: startSize.height - progressDiffHeight)
    }
}
