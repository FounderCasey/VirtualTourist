//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/23/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import Foundation
import MapKit

class Flickr {
    func convertData(request: [String:AnyObject]? = nil) -> NSData {
        var jsonData: NSData! = nil
        
        do {
            jsonData = try JSONSerialization.data(withJSONObject: request!, options: .prettyPrinted) as NSData!
        } catch let error as NSError {
            print(error)
        }
        parseJSON(response: jsonData) { (result, error) in
            print("Result: \(result)")
        }
        return jsonData
    }
    
    func parseJSON(response: NSData, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        var parsedResults: Any! = nil
        
        do {
            parsedResults = try JSONSerialization.jsonObject(with: response as Data, options: .allowFragments)
            completionHandler(parsedResults as AnyObject, nil)
        } catch let error as NSError {
            completionHandler(nil, error)
        }
    }
    
    static func convertToAnnot(_ pin: CDPin) -> MKPointAnnotation {
        let annot = MKPointAnnotation()
        annot.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
        return annot
    }
    
    static func convertToPin(_ annot: MKAnnotation, _ pin: CDPin) -> CDPin {
        pin.latitude = annot.coordinate.latitude
        pin.longitude = annot.coordinate.longitude
        return pin
    }
}
