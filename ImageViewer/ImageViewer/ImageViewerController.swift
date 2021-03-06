//
//  ImageViewerController.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import UIKit

public protocol ImageViewerControllerDataSource: class {

    func numberOfItems(in imageViewerController: ImageViewerController) -> Int

    func imageViewerController(_ imageViewerController: ImageViewerController, itemAt index: Int) -> ImageViewerItem
}

public protocol ImageViewerDelegate: class {

    func imageViewerController(_ imageViewerController: ImageViewerController, transitionViewForItemAt index: Int) -> UIView?

    func imageViewerController(_ imageViewerController: ImageViewerController, didShowItemAt index: Int)
}

extension ImageViewerDelegate {

    public func imageViewerController(_ imageViewerController: ImageViewerController, didShowItemAt index: Int) { }
}

open class ImageViewerController: UIViewController {

    open weak var dataSource: ImageViewerControllerDataSource?

    open weak var delegate: ImageViewerDelegate?

    open var startIndex: Int = 0

    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

    private var itemViewControllers: [ImageViewerItemViewController] = []

    private var lastPendingViewControllerIndex: Int?

    public private(set) var currentPageIndex: Int? {
        didSet {
            if let index = currentPageIndex {
                delegate?.imageViewerController(self, didShowItemAt: index)
            }
        }
    }

    private var panGestureRecognizer: UIPanGestureRecognizer!

    private var interactiveTransitionController = ImageViewerInteractiveTransitionController()

    public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }

    override open func loadView() {
        super.loadView()
        pageViewController.view.frame = view.bounds
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        pageViewController.dataSource = self
        pageViewController.delegate = self
        addChild(pageViewController)
        reload()

        addTapGestureRecognizers()
        addDisimssPanGestureRecognizer()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .black
    }

    open func reload() {
        itemViewControllers.removeAll()

        if let dataSource = dataSource {
            let count = dataSource.numberOfItems(in: self)
            // swiftlint:disable:next identifier_name
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
            pageViewController.setViewControllers([UIViewController()], direction: .forward, animated: false, completion: nil)
        }
    }

    private func addTapGestureRecognizers() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnView(_:)))
        view.addGestureRecognizer(singleTapGesture)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapOnView(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)

        singleTapGesture.require(toFail: doubleTapGesture)
    }

    private func addDisimssPanGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanOnView(_:)))
        panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(panGesture)
        panGestureRecognizer = panGesture
        interactiveTransitionController.panGestureRecognizer = panGesture
    }

    @objc private func handleTapOnView(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func handleDoubleTapOnView(_ sender: UITapGestureRecognizer) {
        guard let currentPage = currentPageIndex else {
            return
        }
        itemViewControllers[currentPage].toggleZoom()
    }

    @objc private func handlePanOnView(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            interactiveTransitionController.initiallyInteractive = true
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
}

extension ImageViewerController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // swiftlint:disable:next force_cast
        guard let index = itemViewControllers.firstIndex(of: viewController as! ImageViewerItemViewController) else {
            return nil
        }
        guard index + 1 < itemViewControllers.count else {
            return nil
        }
        return itemViewControllers[index + 1]
    }

    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // swiftlint:disable:next force_cast
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

    open func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first as? ImageViewerItemViewController  else {
            return
        }
        lastPendingViewControllerIndex = itemViewControllers.firstIndex(of: viewController)
    }

    open func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        currentPageIndex = lastPendingViewControllerIndex
    }
}

extension ImageViewerController: UIViewControllerTransitioningDelegate {

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        interactiveTransitionController.isPresenting = true
        if let sourceView = delegate?.imageViewerController(self, transitionViewForItemAt: startIndex) {
            interactiveTransitionController.sourceView = sourceView
        }
        return interactiveTransitionController
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        interactiveTransitionController.isPresenting = false
        if let currentPageIndex = currentPageIndex, let targetView = delegate?.imageViewerController(self, transitionViewForItemAt: currentPageIndex) {
            itemViewControllers[currentPageIndex].resetZoomScale()
            interactiveTransitionController.sourceView = itemViewControllers[currentPageIndex].imageZoomingView.imageView
            interactiveTransitionController.targetView = targetView
        }
        return interactiveTransitionController
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if interactiveTransitionController.wantsInteractiveStart {
            return interactiveTransitionController
        } else {
            return nil
        }
    }
}
