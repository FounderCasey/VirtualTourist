//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/23/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import Foundation

struct Constants {
    
    struct Flickr {
        static let apiScheme = "https"
        static let apiHost = "api.flickr.com"
        static let apiPath = "/services/rest"
        
        static let searchBBoxHalfWidth = 1.0
        static let searchBBoxHalfHeight = 1.0
        static let searchLatRange = (-90.0, 90.0)
        static let searchLonRange = (-180.0, 180.0)
        static let photoLimit = 20
    }
    
    struct FlickrParameterKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let extras = "extras"
        static let format = "format"
        static let noJSONCallback = "nojsoncallback"
        static let text = "text"
        static let boundingBox = "bbox"
        static let page = "page"
        static let perPage = "per_page"
    }
    
    struct FlickrParameterValues {
        static let method = "flickr.photos.getRecent"
        static let apiKey = "5df473ec1599bd6ae2c5f81e56f66199"
        static let responseFormat = "json"
        static let disableJSONCallback = "1"
        static let mediumURL = "url_m"
        static let photosPerPage = "20"
    }
    
    struct FlickrResponseKeys {
        static let status = "stat"
        static let photos = "photos"
        static let photo = "photo"
        static let mediumURL = "url_m"
        static let pages = "pages"
        static let total = "total"
    }
}
