//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/17/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var pins = [CDPin]()
    var selected: CDPin? = nil
    
    let stack = CoreDataStack.sharedInstace()
    var coord: CLLocationCoordinate2D?
    var longCoord: CLLocationDegrees?
    var latCoord: CLLocationDegrees?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        longPress()
        loadPins()
    }
    
    func longPress() {
        let press = UILongPressGestureRecognizer(target: self, action: #selector(self.addPin(gestureRecognizer:)))
        press.minimumPressDuration = 0.5
        press.delegate = self
        self.mapView.addGestureRecognizer(press)
    }
    
    func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let point = gestureRecognizer.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            let lat = coord.latitude
            let long = coord.longitude
            
            let pin = CDPin(context: stack.persistentContainer.viewContext)
            pin.latitude = lat
            pin.longitude = long
            
            let annot = MKPointAnnotation()
            annot.coordinate = coord
            mapView.addAnnotation(annot)
            stack.saveContext()
        }
    }
    
    func loadPins() {
        var annots = [MKAnnotation]()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDPin")
        
        do {
            let results = try stack.persistentContainer.viewContext.fetch(fetchRequest)
            if let results = results as? [CDPin] {
                pins = results
                print(pins.count)
            }
        } catch {
            print("Unable to find Pins")
        }
        
        for (_, item) in pins.enumerated() {
            let annot = MKPointAnnotation()
            annot .coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(item.latitude), longitude: CLLocationDegrees(item.longitude))
            annots.append(annot)
        }
        mapView.addAnnotations(annots)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuse = "pin"
        
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: reuse) as? MKPinAnnotationView
        
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuse)
        } else {
            pin!.annotation = annotation
        }
        
        pin!.pinTintColor = .blue
        pin?.animatesDrop = true
        return pin
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annot = view.annotation else {
            return
        }
        mapView.selectAnnotation(annot, animated: true)
        performSegue(withIdentifier: "photoAlbum", sender: annot)
        mapView.deselectAnnotation(annot, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoAlbum" {
            var pin: CDPin!
            do {
                let pinAnnot = sender as! MKAnnotation
                let fetchRequest = NSFetchRequest<CDPin>(entityName: "CDPin")
                let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [pinAnnot.coordinate.latitude, pinAnnot.coordinate.longitude])
                fetchRequest.predicate = predicate
                let pins = try stack.persistentContainer.viewContext.fetch(fetchRequest)
                pin = pins[0]
            } catch let error as NSError {
                print(error.localizedDescription)
                return
            }
            let controller = segue.destination as! PhotoAlbumViewController
            controller.pin = Flickr.convertToPin(sender as! MKAnnotation, pin)
        }
    }
}
