//
//  ImageViewerItem.swift
//  ImageViewer
//
//  Created by your3i on 2018/11/04.
//  Copyright © 2018 your3i. All rights reserved.
//

import Foundation

public struct ImageViewerItem {
    var url: String
    var original: String?

    public init(url: String, original: String?) {
        self.url = url
        self.original = original
    }
}
