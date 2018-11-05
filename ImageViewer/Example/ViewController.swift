//
//  ViewController.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import Kingfisher
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    
    let data = [
        ImageViewerItem(url: "https://placehold.jp/150x150.png", original: "https://placehold.jp/9dde8a/ffffff/1024x1024.png"),
        ImageViewerItem(url: "https://placehold.jp/d8a4eb/ffffff/1000x1000.png", original: "https://placehold.jp/a4e5eb/ffffff/4000x4000.png"),
        ImageViewerItem(url: "https://placehold.jp/fc657b/ffffff/800x200.png", original: "https://placehold.jp/fc657b/ffffff/4000x1000.png")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView1.kf.setImage(with: URL(string: data[0].url))
        imageView2.kf.setImage(with: URL(string: data[1].url))
        imageView3.kf.setImage(with: URL(string: data[2].url))
    }

    @IBAction func handleImage1Tapped(_ sender: Any) {
        let viewController = ImageViewerController.viewController()
        viewController.dataSource = self
        viewController.delegate = self
        viewController.startIndex = 0
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func handleImage2Tapped(_ sender: Any) {
        let viewController = ImageViewerController.viewController()
        viewController.dataSource = self
        viewController.delegate = self
        viewController.startIndex = 1
        present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func handleImage3Tapped(_ sender: Any) {
        let viewController = ImageViewerController.viewController()
        viewController.dataSource = self
        viewController.delegate = self
        viewController.startIndex = 2
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: ImageViewerControllerDataSource {

    func numberOfItems(in imageViewerController: ImageViewerController) -> Int {
        return data.count
    }

    func imageViewerController(_ imageViewerController: ImageViewerController, itemAt index: Int) -> ImageViewerItem {
        return data[index]
    }
}

extension ViewController: ImageViewerDelegate {

    func imageViewerController(_ imageViewerController: ImageViewerController, transitionViewForItemAt index: Int) -> UIView {
        let views: [UIImageView] = [imageView1, imageView2, imageView3]
        guard 0..<views.count ~= index else {
            return view
        }
        return views[index]
    }
}

