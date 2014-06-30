//
//  ViewController.swift
//  ZipGet
//
//  Created by Andrew Moore on 6/26/14.
//
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
                            
    @IBOutlet var searchField: UITextField
    @IBOutlet var findBtn: UIButton
    @IBOutlet var zipcode: UILabel
    @IBOutlet var mapView: MKMapView
    @IBOutlet var message: UILabel
    
    let zipCodeFinder = ZipCodeFinder()
    
    var locationManager: CLLocationManager
    var latestLocation: CLLocation?
    
    init(coder aDecoder: NSCoder!) {
        self.locationManager = CLLocationManager()
        super.init(coder: aDecoder)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.locationManager  = CLLocationManager()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func findMe() {
        searchField.endEditing(true);
        
        if let coords = latestLocation?.coordinate {
            mapView.setRegion(MKCoordinateRegionMake(coords, MKCoordinateSpanMake(0.5, 0.5)), animated: true)
        } else {
            let newZip = zipCodeFinder.findZipCode(forCoordinate: mapView.centerCoordinate)
            setNewZipCode(newZip)
        }
    }
    
    func setNewZipCode(newZipCode: String) {
        // Plan: animate text as it increments/decrements to new zip
        zipcode.text = newZipCode
    }
    
    // Location manager delegate methods
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]) {
        latestLocation = locations[locations.endIndex] as? CLLocation
        NSLog("Updated locations")
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError) {
        message.text = error.localizedDescription
    }
    
    // Text field delegate methods
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField!) {
    
    }
}