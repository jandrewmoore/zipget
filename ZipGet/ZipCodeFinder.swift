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
    
    init(_ username: String) {
        self.username = username
    }

    func findZipCode(forCoordinate coord: CLLocationCoordinate2D, onSuccess: (String) -> Void, onError: (String?) -> Void) {
        let url = "http://api.geonames.org/findNearbyPostalCodesJSON"
        let parameters: [String: AnyObject] = [
            "lat": coord.latitude,
            "lng": coord.longitude,
            "username": username,
            "maxRows": 1
        ]

        latestCoordinates = coord

        Alamofire.request(.GET, url, parameters: parameters).response { _, _, data, _ in
            let json = JSONValue(data as NSData)

            if let message = json["status"]["message"].string {
                onError("Error: \(message)")
            } else if let postalCode = json["postalCodes"][0]["postalCode"].string {
                onSuccess(postalCode as String)
            } else {
                NSLog("No postal code at \(coord.latitude), \(coord.longitude)")
                onError("Couldn't find a postal code here 😱")
            }
        }
    }
    
    func findZipCode(forCityName city: String, onSuccess: (String) -> Void, onError: (String?) -> Void) {
        var url = "http://api.geonames.org/searchJSON"
        var parameters: [String: AnyObject] = [
            "username": username,
            "maxRows": 1
        ]
        
        let cityParts = city.componentsSeparatedByString(", ")

        parameters["name_equals"] = cityParts[0]
        
        if cityParts.count > 1 {
            parameters["adminCode1"] = cityParts[1]
        }

        Alamofire.request(.GET, url, parameters: parameters).response { _, _, data, _ in
            let json = JSONValue(data as NSData)

            if let message = json["status"]["message"].string {
                onError("Error: \(message)")
            }

            let lat = json["geonames"][0]["lat"].double
            let lng = json["geonames"][0]["lng"].double
            if lat && lng {
                self.latestCoordinates = CLLocationCoordinate2DMake(lat!, lng!)
                self.findZipCode(forCoordinate: self.latestCoordinates!, onSuccess: onSuccess, onError: onError)
            } else {
                onError("Is '\(city)' even a real place?")
            }
        }
    }
}