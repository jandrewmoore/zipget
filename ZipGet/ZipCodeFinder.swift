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
    func findZipCode(forCoordinate coordinate: CLLocationCoordinate2D) -> String {
        let fake = Int(arc4random_uniform(90000)) + 10000
        return "\(fake)"
    }
}