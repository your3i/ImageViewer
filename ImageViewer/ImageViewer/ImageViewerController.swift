//
//  ImageViewerController.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

protocol ImageViewerControllerDataSource: class {

    func numberOfItems(in imageViewerController: ImageViewerController) -> Int

    func imageViewerController(_ imageViewerController: ImageViewerController, itemAt index: Int) -> ImageViewerItem
}

protocol ImageViewerDelegate: class {

    func imageViewerController(_ imageViewerController: ImageViewerController, transitionViewForItemAt index: Int) -> UIView?
}

class ImageViewerController: UIViewController {

    weak var dataSource: ImageViewerControllerDataSource?

    weak var delegate: ImageViewerDelegate?

    var startIndex: Int = 0

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

    private var itemViewControllers: [ImageViewerItemViewController] = []

    private var lastPendingViewControllerIndex: Int?

    private var currentPageIndex: Int?

    static func viewController() -> ImageViewerController {
        let viewController = ImageViewerController()
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = viewController
        return viewController
    }

    override func loadView() {
        super.loadView()
        pageViewController.view.frame = view.bounds
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pageViewController.dataSource = self
        pageViewController.delegate = self
        reload()

        addTapDismissGestureRecognizer()
    }

    func reload() {
        itemViewControllers.removeAll()

        if let dataSource = dataSource {
            let count = dataSource.numberOfItems(in: self)
            for i in 0..<count {
                let item = dataSource.imageViewerController(self, itemAt: i)
                let viewController = ImageViewerItemViewController.viewController(item)
                itemViewControllers.append(viewController)
            }
        }

        if 0..<itemViewControllers.count ~= startIndex {
            pageViewController.setViewControllers([itemViewControllers[startIndex]], direction: .forward, animated: false, completion: nil)
            currentPageIndex = startIndex
        } else if let firstViewController = itemViewControllers.first {
            pageViewController.setViewControllers([firstViewController], direction: .forward, animated: false, completion: nil)
            currentPageIndex = 0
        } else {
            pageViewController.setViewControllers([], direction: .forward, animated: false, completion: nil)
        }
    }

    private func addTapDismissGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnView(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapOnView(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}

extension ImageViewerController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = itemViewControllers.firstIndex(of: viewController as! ImageViewerItemViewController) else {
            return nil
        }
        guard index + 1 < itemViewControllers.count else {
            return nil
        }
        return itemViewControllers[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = itemViewControllers.firstIndex(of: viewController as! ImageViewerItemViewController) else {
            return nil
        }
        guard index - 1 >= 0 else {
            return nil
        }
        return itemViewControllers[index - 1]
    }

    // FIXME: UIPageViewController puts viewControllers above UIPageControl and it makes images' center change.

//    func presentationCount(for pageViewController: UIPageViewController) -> Int {
//        return itemViewControllers.count
//    }
//
//    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
//        return startIndex
//    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first as? ImageViewerItemViewController  else {
            return
        }
        lastPendingViewControllerIndex = itemViewControllers.firstIndex(of: viewController)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        currentPageIndex = lastPendingViewControllerIndex
    }
}

extension ImageViewerController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return ImageViewerPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = ImageViewerTransitionAnimator.instanceForPresent()
        if let sourceView = delegate?.imageViewerController(self, transitionViewForItemAt: startIndex) {
            animator.sourceView = sourceView
        }
        return animator
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = ImageViewerTransitionAnimator.instanceForDismiss()
        if let currentPageIndex = currentPageIndex, let destinationView = delegate?.imageViewerController(self, transitionViewForItemAt: currentPageIndex) {
            animator.sourceView = itemViewControllers[currentPageIndex].imageView
            animator.destinationView = destinationView
        }
        return animator
    }
}
