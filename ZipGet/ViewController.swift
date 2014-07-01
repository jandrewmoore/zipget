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
    @IBOutlet var zipCode: UILabel
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
        
        zipCode.text = zipCodeFinder.getFirstZipCode()
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
            var newZip: String
            zipCodeFinder.findZipCode(forCoordinate: mapView.centerCoordinate, onSuccess: setNewZipCode)
        }
    }
    
    func setNewZipCode(newZipCode: String) {
        // Plan: animate text as it increments/decrements to new zip
        if newZipCode == zipCode.text {
            animateMessage("You're in the same zip code!")
        } else {
            zipCode.text = newZipCode
            clearMessage()
        }
    }
    
    func animateMessage(newMessage: String) {
        message.alpha = 0.0
        message.text = newMessage
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationCurve(UIViewAnimationCurve.EaseOut)
        UIView.setAnimationDuration(2.0)
        
        message.alpha = 1.0
        
        UIView.commitAnimations()
    }
    
    func clearMessage() {
        message.text = ""
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
        // Do something with the text.
    }
}