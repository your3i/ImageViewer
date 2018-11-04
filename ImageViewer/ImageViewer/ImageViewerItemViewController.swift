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

    private let imageZoomingView = ImageViewerScrollView()

    private var item: ImageViewerItem!

    private var originalLoaded = false

    var imageView: UIImageView {
        return imageZoomingView.imageView
    }

    static func viewController(_ item: ImageViewerItem) -> ImageViewerItemViewController {
        let viewController = ImageViewerItemViewController()
        viewController.item = item
        viewController.originalLoaded = item.original == nil
        return viewController
    }

    override func loadView() {
        super.loadView()
        imageZoomingView.frame = view.bounds
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
        imageZoomingView.imageView.kf.setImage(with: URL(string: item.url)) { [weak self] (image, error, _, _) in
            guard let image = image else {
                return
            }
            self?.imageZoomingView.image = image
        }
    }

    private func loadOriginalIfNeeded() {
        guard !originalLoaded, let url = item.original else {
            return
        }
        imageZoomingView.imageView.kf.indicatorType = .activity
        imageZoomingView.imageView.kf.setImage(with: URL(string: url)) { [weak self] (image, error, _, _) in
            guard let image = image else {
                return
            }
            self?.imageZoomingView.image = image
            self?.originalLoaded = true
        }
    }
}
