//
//  PhotoCell.swift
//  Flexible UICollectionView Layouts
//
//  Created by Charles Martin Reed on 1/23/19.
//  Copyright © 2019 Charles Martin Reed. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    //MARK:- Properties
    override var isSelected: Bool {
        didSet {
            imageView.layer.borderWidth = isSelected ? 10 : 0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.borderColor = themeColor.cgColor
        isSelected = false
    }
    
    //MARK:- IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
}
