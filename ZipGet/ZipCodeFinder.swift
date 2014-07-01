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
    
    let myZipCodes = ["96701", "76522", "42303", "47803", "47807", "46032", "46220"]
    let manager: AFHTTPRequestOperationManager
    
    init() {
        self.manager = AFHTTPRequestOperationManager()
    }
    
    func getFirstZipCode() -> String {
        return myZipCodes[Int(arc4random_uniform(UInt32(myZipCodes.count - 1)))]
    }
    
    func findZipCode(forCoordinate coord: CLLocationCoordinate2D, onSuccess: (String) -> Void) {
        let url = "http://api.geonames.org/findNearbyPostalCodesJSON" +
            "?lat=\(coord.latitude)&lng=\(coord.longitude)&username=\(username)&maxRows=1"
        
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
    }
}