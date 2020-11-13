//
//  SpotPhotoCollectionViewCell.swift
//  Snacktacular
//
//  Created by John Pappas on 11/13/20.
//  Copyright © 2020 John Pappas. All rights reserved.
//

import UIKit

class SpotPhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    
    var spot: Spot!
    var photo: Photo! {
        didSet {
            photo.loadImage(spot: spot) { (success) in
                if success {
                    self.photoImageView.image = self.photo.image
                } else {
                    print("error. no success with photo")
                }
            }
        }
    }
}
