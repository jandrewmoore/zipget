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
    let username = "jamoore"
    let manager: AFHTTPRequestOperationManager
    
    init() {
        self.manager = AFHTTPRequestOperationManager()
    }
    
    func findZipCode(forCoordinate coord: CLLocationCoordinate2D, onSuccess: (String) -> Void) {
        let url = "http://api.geonames.org/findNearbyPostalCodesJSON" +
            "?lat=\(coord.latitude)&lng=\(coord.longitude)&username=\(username)"
        
        manager.GET(url,
            parameters: nil,
            success: { (op: AFHTTPRequestOperation!, response: AnyObject!)
                in
                let json = response as Dictionary<String, AnyObject>
                let postalCodes: AnyObject? = json["postalCodes"]
                let first: AnyObject? = postalCodes?[0]
                if let res: AnyObject! = first?["postalCode"] {
                    onSuccess(res as String)
                } else {
                    onSuccess("!!!!!")
                }
            }, failure: { (op: AFHTTPRequestOperation!, error: NSError!)
                in
                println("Error: \(error.localizedDescription)")
            })
        
//        let fake = Int(arc4random_uniform(90000)) + 10000
    }
}