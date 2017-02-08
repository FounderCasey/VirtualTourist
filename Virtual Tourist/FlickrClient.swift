//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/17/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import Foundation
import MapKit

class FlickrClient {
    
    var session = URLSession.shared
    var randomPage = arc4random_uniform(15)
    
    func getPhotos(lat: Double, long: Double, completionHandler: @escaping (_ url: [String]?, _ error: NSError?) -> Void) {
        let parameters: [String:AnyObject] = [
            Constants.FlickrParameterKeys.method: Constants.FlickrParameterValues.method as AnyObject,
            Constants.FlickrParameterKeys.apiKey: Constants.FlickrParameterValues.apiKey as AnyObject,
            Constants.FlickrParameterKeys.boundingBox: self.makeBoundaryBox(lat: lat, long: long) as AnyObject,
            Constants.FlickrParameterKeys.extras: Constants.FlickrParameterValues.mediumURL as AnyObject,
            Constants.FlickrParameterKeys.format: Constants.FlickrParameterValues.responseFormat as AnyObject,
            Constants.FlickrParameterKeys.noJSONCallback: Constants.FlickrParameterValues.disableJSONCallback as AnyObject,
            Constants.FlickrParameterKeys.perPage: Constants.FlickrParameterValues.photosPerPage as AnyObject,
            Constants.FlickrParameterKeys.page: "\(randomPage)" as AnyObject
        ]
        
        let request = URLRequest(url: flickrUrl(parameters))
        initiateAPICall(request: request) { (data, error) in
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else {
                sendError("Request error : \(error)")
                return
            }
            
            guard let data = data else {
                sendError("No Data was returned")
                return
            }
            
            guard let status = data[Constants.FlickrResponseKeys.status] as? String, status == "ok" else {
                completionHandler(nil, NSError(domain: "Search", code: 5001, userInfo: [NSLocalizedDescriptionKey: "API Error"]))
                return
            }
            
            if let photosDict = data[Constants.FlickrResponseKeys.photos] as? [String:AnyObject],
                let photosArray = photosDict[Constants.FlickrResponseKeys.photo] as? [[String:AnyObject]] {
                var urls = [String]()
                
                for photo in photosArray {
                    if let photoURL = photo[Constants.FlickrResponseKeys.mediumURL] as? String {
                        urls.append(photoURL)
                    }
                }
                completionHandler(urls, nil)
            } else {
                completionHandler(nil, NSError(domain: "Search", code: 5002, userInfo: [NSLocalizedDescriptionKey: "Bad Response"]))
            }
        }
    }
    
    func downloadPhotos(photoUrl: String, completionHandler: @escaping (_ image: NSData?, _ error: NSError?) -> Void) {
        let url = NSURL(string: photoUrl)
        let request = URLRequest(url: url as! URL)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, NSError(domain: "Download", code: 6001, userInfo: [NSLocalizedDescriptionKey: "Download Error"]))
                return
            }
            completionHandler(data as NSData, nil)
        }
        task.resume()
    }
    
    func initiateAPICall(request: URLRequest, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
        let session = URLSession.shared
        
        let task =  session.dataTask(with: request) { (data, response, error) in
            if error == nil {
                self.parseJSON(response: data! as NSData, completionHandler: completionHandler)
            } else {
                completionHandler(nil, error as NSError?)
            }
        }
        
        task.resume()
    }
    
    private func makeBoundaryBox(lat: Double, long: Double) -> String {
        let minLat = max(lat - Constants.Flickr.searchBBoxHalfHeight, Constants.Flickr.searchLatRange.0)
        let minLong = max(long - Constants.Flickr.searchBBoxHalfWidth, Constants.Flickr.searchLonRange.0)
        let maxLat = max(lat + Constants.Flickr.searchBBoxHalfHeight, Constants.Flickr.searchLatRange.1)
        let maxLong = max(long + Constants.Flickr.searchBBoxHalfWidth, Constants.Flickr.searchLonRange.1)
        
        return "\(minLong),\(minLat),\(maxLong),\(maxLat)"
    }
    
    private func flickrUrl(_ parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.apiScheme
        components.host = Constants.Flickr.apiHost
        components.path = Constants.Flickr.apiPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
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
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
