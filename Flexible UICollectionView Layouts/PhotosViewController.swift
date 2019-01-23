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
    
    private var selectedPhotos = [FlickrPhoto]()
    private var shareLabel = UILabel()
    var sharing: Bool = false {
        didSet {
            collectionView.allowsMultipleSelection = sharing
            
            //when not sharing
            collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
            selectedPhotos.removeAll()
            
            guard let shareButton = self.navigationItem.rightBarButtonItems?.first else { return }
            
            //if sharing, add buttons to the top right of nav
            guard sharing else {
                navigationItem.setRightBarButton(shareButton, animated: true)
                return
            }
            
            if largePhotoIndexPath != nil {
                largePhotoIndexPath = nil
            }
            
            updateSharedPhotoCountLabel()
            
            let sharingItem = UIBarButtonItem(customView: shareLabel)
            let items: [UIBarButtonItem] = [shareButton, sharingItem]
            
            navigationItem.setRightBarButtonItems(items, animated: true)
        }
    }
    
    var largePhotoIndexPath: IndexPath? { //optionally holds the currently selected photo
        didSet {
            var indexPaths = [IndexPath]()
            if let largePhotoIndexPath = largePhotoIndexPath {
                indexPaths.append(largePhotoIndexPath)
            }
            
            if let oldValue = oldValue {
                indexPaths.append(oldValue)
                self.collectionView.reloadItems(at: indexPaths)
                collectionView.scrollToItem(at: oldValue, at: .top, animated: true)
            }
            
            collectionView.performBatchUpdates({ //if this prop changes, update the colletionView
                self.collectionView.reloadItems(at: indexPaths)
            }) { (_) in
                if let largePhotoIndexPath = self.largePhotoIndexPath {
                    self.collectionView.scrollToItem(at: largePhotoIndexPath, at: .centeredVertically, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
    }
    
    //MARK:- IBActions
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        
        guard !searches.isEmpty else { return }
        guard !selectedPhotos.isEmpty else {
            sharing.toggle()
            return }
        guard sharing else { return }
        
        //whew. If you're here, you can share some photos.
        let images: [UIImage] = selectedPhotos.compactMap { photo in
            if let thumbnail = photo.thumbnail {
                return thumbnail
            }
            return nil
        }
        
        guard !images.isEmpty else { return }
        
        //if we've got images to share, build a share controller with all photo objects
        let shareController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        shareController.completionWithItemsHandler = { _, _, _, _ in
            self.sharing = false
            self.selectedPhotos.removeAll()
            self.updateSharedPhotoCountLabel()
        }
        
        //present the shareController
        shareController.popoverPresentationController?.barButtonItem = sender
        shareController.popoverPresentationController?.permittedArrowDirections = .any
        present(shareController, animated: true, completion: nil)
        
    }
}

//MARK:- private convenience methods for laying out photos
private extension PhotosViewController {
    func photo(for indexPath: IndexPath) -> FlickrPhoto {
        return searches[indexPath.section].searchResults[indexPath.row]
    }
    
    //method for downloading the large version of an image from Flickr and displaying it
    func performLargeImageFetch(for indexPath: IndexPath, flickrPhoto: FlickrPhoto) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell else { return }
        
        cell.activityIndicator.startAnimating()
        
        flickrPhoto.loadLargeImage { [unowned self] result in
        
            switch result { //either we get back a photo or we are unable to obtain one
            case .results(let photo):
                if indexPath == self.largePhotoIndexPath { //if we've selected an imag
                    cell.imageView.image = photo.largeImage
                }
            case .error(_):
                return
            }
        }
    }
    
    func updateSharedPhotoCountLabel() {
        if sharing {
            shareLabel.text = "\(selectedPhotos.count) photos selected"
        } else {
            shareLabel.text = ""
        }
        
        shareLabel.textColor = themeColor
        
        UIView.animate(withDuration: 0.3) {
            self.shareLabel.sizeToFit()
        }
    }
    
    func removePhoto(at indexPath: IndexPath) {
        searches[indexPath.section].searchResults.remove(at: indexPath.row)
    }
    
    func insertPhoto(_ flickrPhoto: FlickrPhoto, at indexPath: IndexPath) {
        searches[indexPath.section].searchResults.insert(flickrPhoto, at: indexPath.row)
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

//MARK:- UICollectionViewDelegate
extension PhotosViewController {
    //tells the collection view whether or not it should select a specific cell
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        guard !sharing else { return true } //if we're sharing, just select item as usual.
        
        if largePhotoIndexPath == indexPath {
            largePhotoIndexPath = nil
        } else {
            largePhotoIndexPath = indexPath //fires the didSet in largePhotoIndexPath
        }
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard sharing else { return }
        
        let flickrPhoto = photo(for: indexPath)
        selectedPhotos.append(flickrPhoto)
        updateSharedPhotoCountLabel()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard sharing else { return }
        
        let flickrPhoto = photo(for: indexPath)
        if let index = selectedPhotos.firstIndex(of: flickrPhoto) {
            selectedPhotos.remove(at: index)
            updateSharedPhotoCountLabel()
        }
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifer, for: indexPath) as? PhotoCell else { preconditionFailure("Invalid cell type") }
        
        //user our convenience method to find a photo, given an indexPath
        let flickrPhoto = photo(for: indexPath)
        cell.activityIndicator.stopAnimating()
        
        guard indexPath == largePhotoIndexPath else { //if these don't match, use the thumbnail
            cell.imageView.image = flickrPhoto.thumbnail
            return cell
        }
        
        guard flickrPhoto.largeImage == nil else { //if large image is not nil, display the large image in the cell
            cell.imageView.image = flickrPhoto.largeImage
            return cell
        }
        
        cell.imageView.image = flickrPhoto.thumbnail
        performLargeImageFetch(for: indexPath, flickrPhoto: flickrPhoto)
        
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
        
        if indexPath == largePhotoIndexPath {
            let flickrPhoto = photo(for: indexPath)
            var size = collectionView.bounds.size
            size.height -= (sectionInsets.top + sectionInsets.bottom)
            size.width -= (sectionInsets.left + sectionInsets.right)
            return flickrPhoto.sizeToFillWidth(of: size)
        }
        
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

//MARK:- UICollectionViewDragDelegate
extension PhotosViewController : UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let flickrPhoto = photo(for: indexPath)
        guard let thumbnail = flickrPhoto.thumbnail else {
            return []
        }
        
        let item = NSItemProvider(object: thumbnail) //encapsulate the object for sharing between processes
        let dragItem = UIDragItem(itemProvider: item)
        return [dragItem] //even if we're just dragging one photo, this requires returning an array
    }
}


//MARK:- UICollectionViewDropDelegate
extension PhotosViewController : UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        //get drop destination from coordinator
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        coordinator.items.forEach { dropItem in
            //if each item passed to the coordinator has a source index path...
            guard let sourceIndexPath = dropItem.sourceIndexPath else { return }
            
            collectionView.performBatchUpdates({
                //remove the item in collection at the source path, then insert them at the proposed destination
                let image = photo(for: sourceIndexPath)
                removePhoto(at: sourceIndexPath)
                insertPhoto(image, at: destinationIndexPath)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [destinationIndexPath])
            }, completion: { (_) in
                //when the collectionView has been successfully updated, drop the items in their new locations
                coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        //this would normally be used to determine whether or not the drag item(s) should be allowed to drop, but we're only dealing with a single type within our own app here so it's OK to simply return true without additional checks
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    
    
}
