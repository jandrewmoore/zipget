//
//  ZipCodeFinder.swift
//  ZipGet
//
//  Created by Andrew Moore on 6/27/14.
//
//

import Foundation
import MapKit

class ZipCodeFinder {
    var latestCoordinates: CLLocationCoordinate2D?
    
    var username: String!
    let manager: AFHTTPRequestOperationManager
    
    init(_ username: String) {
        self.manager = AFHTTPRequestOperationManager()
        self.username = username
    }
        
    func findZipCode(forCoordinate coord: CLLocationCoordinate2D, onSuccess: (String) -> Void, onError: (String?) -> Void) {
        let url = "http://api.geonames.org/findNearbyPostalCodesJSON" +
            "?lat=\(coord.latitude)&lng=\(coord.longitude)&username=\(username)&maxRows=1"
        latestCoordinates = coord
        
        manager.GET(url,
            parameters: nil,
            success: { (op: AFHTTPRequestOperation!, response: AnyObject!) in
                let json = response as Dictionary<String, AnyObject>
                let postalCodes: AnyObject? = json["postalCodes"]
                let postalCodesArr = postalCodes as Array<Dictionary<String, AnyObject>>
                if !postalCodesArr.isEmpty {
                    let first = postalCodesArr[0]
                    if let res: AnyObject = first["postalCode"] {
                        onSuccess(res as String)
                        return
                    }
                }
                
                onError("Couldn't find a postal code here 😱")
            }, failure: { (op: AFHTTPRequestOperation!, error: NSError!) in
                onError(error.localizedDescription)
            })
    }
    
    func findZipCode(forCityName city: String, onSuccess: (String) -> Void, onError: (String?) -> Void) {
        var url = "http://api.geonames.org/searchJSON"
        
        var parameters: Dictionary<String, AnyObject> = [
            "username": username,
            "maxRows": 1
        ]
        
        let cityParts = city.componentsSeparatedByString(", ")

        parameters["name_equals"] = cityParts[0]
        
        if cityParts.count > 1 {
            parameters["adminCode1"] = cityParts[1]
        }
        
        manager.GET(url,
            parameters: parameters,
            success: { (op: AFHTTPRequestOperation!, response: AnyObject!) in
                let json = response as Dictionary<String, AnyObject>
                let results: AnyObject? = json["geonames"]
                let resultsArray = results as Array<Dictionary<String, AnyObject>>
                if !resultsArray.isEmpty {
                    let first = resultsArray[0]
                    var lat: AnyObject? = first["lat"]
                    var lng: AnyObject? = first["lng"]

                    lat = lat as? String
                    lng = lng as? String
                    
                    if lat && lng {
                        self.latestCoordinates = CLLocationCoordinate2DMake(lat!.doubleValue, lng!.doubleValue)
                        self.findZipCode(forCoordinate: self.latestCoordinates!, onSuccess: onSuccess, onError: onError)
                        return
                    }
                }
                
                onError("Could not find '\(city)'")
            },
            failure: { (op: AFHTTPRequestOperation!, error: NSError!) in
                onError(error.localizedDescription)
            })
    }
}