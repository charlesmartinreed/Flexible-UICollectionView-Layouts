//
//  PhotosCollectionViewController.swift
//  Flexible UICollectionView Layouts
//
//  Created by Charles Martin Reed on 1/23/19.
//  Copyright © 2019 Charles Martin Reed. All rights reserved.
//

import UIKit



final class PhotosViewController: UICollectionViewController {
    
    //MARK:- Properties
    private let reuseIdentifer = "PhotoCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    private var searches = [FlickrSearchResults]() //tracks all searches made in app
    private var flickr = Flickr() //obj that performs the searches
    private let itemsPerRow: CGFloat = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
}

//MARK:- Convienience method for laying out photos
private extension PhotosViewController {
    func photo(for indexPath: IndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
}

//MARK:- UITextFieldDelegate extension
extension PhotosViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        textField.addSubview(activityIndicator)
        activityIndicator.frame = textField.bounds
        activityIndicator.startAnimating()
        
        flickr.searchFlickr(for: textField.text!) { searchResults in
            activityIndicator.removeFromSuperview()
            
            switch searchResults {
            case .error(let error):
                print("Error Searching: \(error)")
            case .results(let results):
                print("Found \(results.searchResults.count) matching \(results.searchTerm)")
                self.searches.insert(results, at: 0)
                self.collectionView.reloadData()
            }
        }
        
        textField.text = nil
        textField.resignFirstResponder()
        return true
    }
}

//MARK:- UICollectionViewDataSource extension
extension PhotosViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return searches.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches[section].searchResults.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifer, for: indexPath) as? PhotoCell else { fatalError("Could not create cell") }
        
        //user our convenience method to find a photo, given an indexPath
        let flickrPhoto = photo(for: indexPath)
        cell.backgroundColor = .white
        cell.imageView.image = flickrPhoto.thumbnail
        
        
        return cell
    }
    
    //MARK:- Supplemental view extension
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "\(PhotoHeaderView.self)", for: indexPath) as? PhotoHeaderView else { fatalError("Invalid view type") }
            let searchTerm = searches[indexPath.section].searchTerm
            headerView.headerLabel.text = searchTerm.uppercased()
            return headerView
        default:
            assert(false, "Invalid element type")
        }
    }
}

//MARK:- UICollectionViewFlowLayout delegate extension
extension PhotosViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        //size of our cells
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return sectionInsets.left
    }
}

