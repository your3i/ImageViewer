//
//  ImageViewerScrollView.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

class ImageViewerScrollView: UIScrollView {

    var image: UIImage? {
        didSet {
            relayout()
        }
    }

    var pinchMaxZoomScale: CGFloat = 5.0

    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        addSubview(imageView)
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        delegate = self
    }

    func relayout() {
        guard let image = image else {
            return
        }

        minimumZoomScale = calculateFitZoomScale()
        maximumZoomScale = pinchMaxZoomScale
        zoomScale = minimumZoomScale

        imageView.frame.size = CGSize(width: image.size.width * zoomScale, height: image.size.height * zoomScale)
        contentSize = imageView.frame.size
        updateInsets()
    }

    func toggleZoom() {
        let nextScale = zoomScale != minimumZoomScale ? minimumZoomScale : 2 * minimumZoomScale
        setZoomScale(nextScale, animated: true)
    }

    func resetZoomScale() {
        setZoomScale(minimumZoomScale, animated: true)
    }

    private func updateInsets() {
        let horizontalInset = max(0, (bounds.width - imageView.frame.width) / 2)
        let verticalInset = max(0, (bounds.height - imageView.frame.height) / 2)
        contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

    private func calculateFitZoomScale() -> CGFloat {
        guard let image = image else {
            return 1.0
        }
        let scaleWidth = bounds.width / image.size.width
        let scaleHeight = bounds.height / image.size.height
        let fitScale = min(scaleWidth, scaleHeight)
        return fitScale
    }
}

extension ImageViewerScrollView: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateInsets()
    }
}
