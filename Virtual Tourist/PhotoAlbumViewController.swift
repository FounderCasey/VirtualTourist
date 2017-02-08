//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/17/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var collectionFlow: UICollectionViewFlowLayout!
    
    let flickr = FlickrClient.sharedInstance()
    let stack = CoreDataStack.sharedInstace()
    
    var pin: CDPin!
    var fetchedResults: NSFetchedResultsController<NSFetchRequestResult>!
    
    var insertIndex: [NSIndexPath]!
    var deleteIndex: [NSIndexPath]!
    
    var cellAlphaShaded: CGFloat = 0.5
    
    var selected = [NSIndexPath]() {
        didSet {
            newCollectionButton.title = selected.isEmpty ? "New Collection" : "Remove Selected Photos"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        mapView.delegate = self
        mapView.addAnnotation(Flickr.convertToAnnot(self.pin))
        mapView.camera.centerCoordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        mapView.camera.altitude = 1000
        
        initializeFlowLayout()
        
        if fetchPhotos().isEmpty {
            getAndDisplayPhotos()
        }
    }
    
    func initializeFlowLayout() {
        collectionView?.contentMode = UIViewContentMode.scaleAspectFit
        
        collectionView?.backgroundColor = UIColor.white
        
        let space : CGFloat = 2.0
        
        let dimension = (UIDevice.current.orientation.isPortrait) ?  (self.view.frame.width - (2 * space)) / 3.0 : (self.view.frame.height - (2 * space)) / 3.0
        collectionFlow.minimumInteritemSpacing = space
        collectionFlow.minimumLineSpacing = space
        collectionFlow.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func newCollection(_ sender: Any) {
        if selected.isEmpty {
            deleteAll()
            getAndDisplayPhotos()
        } else {
            deleteSelected()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

extension PhotoAlbumViewController {
    func getAndDisplayPhotos() {
        self.newCollectionButton.isEnabled = false
        flickr.getPhotos(lat: pin.latitude, long: pin.longitude) { (photoUrls, error) in
            guard photoUrls != nil else {
                return
            }
            
            DispatchQueue.main.async {
                for url in photoUrls! {
                    let photo = Photo(context: self.stack.persistentContainer.viewContext)
                    photo.pin = self.pin
                    photo.url = url
                }
                self.stack.saveContext()
                self.newCollectionButton.isEnabled = true
            }
        }
    }
    
    func deleteAll() {
        for photo in fetchedResults.fetchedObjects as! [Photo] {
            stack.persistentContainer.viewContext.delete(photo)
        }
        stack.saveContext()
    }
    
    func deleteSelected() {
        var selectedPhotos = [Photo]()
        
        for indexPath in selected {
            selectedPhotos.append(fetchedResults.object(at: indexPath as IndexPath) as! Photo)
        }
        
        for photo in selectedPhotos {
            stack.persistentContainer.viewContext.delete(photo)
        }
        stack.saveContext()
        selected = []
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuse = "pin"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuse) as? MKPinAnnotationView
        view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuse)
        view!.pinTintColor = .blue
        return view!
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath as IndexPath) as! CellCollectionViewCell
        
        if let index = selected.index(of: indexPath as NSIndexPath) {
            selected.remove(at: index)
        } else {
            selected.append(indexPath as NSIndexPath)
        }
        configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
    }
    
    func configureCellSection(cell: CellCollectionViewCell, indexPath: NSIndexPath) {
        if let _ = selected.index(of: indexPath) {
            cell.alpha = cellAlphaShaded
        } else {
            cell.alpha = 1.0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResults.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CellCollectionViewCell
        let photo = fetchedResults.object(at: indexPath) as! Photo
        
        if photo.image == nil {
            DispatchQueue.main.async {
                cell.activityIndicator.startAnimating()
            }
            flickr.downloadPhotos(photoUrl: photo.url!) { (image, error)  in
                guard let imageData = image,
                    let downloadedImage = UIImage(data: imageData as Data) else {
                    return
                }
                
                DispatchQueue.main.async {
                        photo.image = imageData
                        self.stack.saveContext()
                        
                        if let update = self.collectionView.cellForItem(at: indexPath) as? CellCollectionViewCell {
                            update.imageView.image = downloadedImage
                            update.activityIndicator.stopAnimating()
                        }
                }
                cell.imageView.image = UIImage(data: imageData as Data)
                self.configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
            }
        } else {
            cell.imageView.image = UIImage(data: photo.image as! Data)
        }
        return cell
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func fetchPhotos() -> [Photo] {
        var photos = [Photo]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        fetchedResults = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResults.delegate = self
        
        do {
            try fetchedResults.performFetch()
            if let results = fetchedResults.fetchedObjects as? [Photo] {
                photos = results
            }
        } catch {
            print("Error while trying to fetch photos.")
        }
        return photos
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndex = [NSIndexPath]()
        deleteIndex = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
                self.collectionView.insertItems(at: self.insertIndex as [IndexPath])
                self.collectionView.deleteItems(at: self.deleteIndex as [IndexPath])
        }, completion: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert: insertIndex.append(newIndexPath! as NSIndexPath)
            case .delete: deleteIndex.append(indexPath! as NSIndexPath)
            default: break
        }
    }
}






