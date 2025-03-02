//
//  UIImafeView+Ext.swift
//  Test
//
//  Created by Al Stark on 02.03.2025.
//

import UIKit

private var imageCache = NSCache<NSURL, UIImage>()

extension UIImageView {
    func loadImage(from url: URL?) {
        guard let url = url else {
            self.image = UIImage(named: "l5w5aIHioYc")
            return
        }

        if let cachedImage = imageCache.object(forKey: url as NSURL) {
            self.image = cachedImage
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: url as NSURL)

                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}
