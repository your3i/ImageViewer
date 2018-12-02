//
//  ImageViewerItemViewController.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import Kingfisher
import UIKit

class ImageViewerItemViewController: UIViewController {

    let imageZoomingView = ImageViewerScrollView()

    private var item: ImageViewerItem!

    private var originalLoaded = false

    static func viewController(_ item: ImageViewerItem) -> ImageViewerItemViewController {
        let viewController = ImageViewerItemViewController()
        viewController.item = item
        viewController.originalLoaded = item.original == nil
        return viewController
    }

    override func loadView() {
        super.loadView()
        imageZoomingView.frame = view.bounds
        imageZoomingView.imageView.kf.indicatorType = .activity
        view.addSubview(imageZoomingView)

        imageZoomingView.translatesAutoresizingMaskIntoConstraints = false
        imageZoomingView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageZoomingView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageZoomingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageZoomingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadOriginalIfNeeded()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.imageZoomingView.relayout()
            }, completion: nil)
    }

    private func loadImage() {
        guard let url = URL(string: item.url) else {
            return
        }
        imageZoomingView.imageView.kf.indicator?.startAnimatingView()
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { [weak self] (image, _, _, _) in
            self?.imageZoomingView.imageView.kf.indicator?.stopAnimatingView()
            if let image = image {
                self?.imageZoomingView.image = image
            }
        }
    }

    private func loadOriginalIfNeeded() {
        guard !originalLoaded, let original = item.original, let url = URL(string: original) else {
            return
        }

        imageZoomingView.imageView.kf.indicator?.startAnimatingView()
        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { [weak self] (image, _, _, _) in
            self?.imageZoomingView.imageView.kf.indicator?.stopAnimatingView()

            guard let image = image else {
                return
            }
            self?.imageZoomingView.image = image
            self?.originalLoaded = true
        }
    }

    func resetZoomScale() {
        imageZoomingView.resetZoomScale()
    }

    func toggleZoom() {
        imageZoomingView.toggleZoom()
    }
}
