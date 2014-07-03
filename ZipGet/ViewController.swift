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

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate {
                            
    @IBOutlet var searchField: UITextField
    @IBOutlet var findBtn: UIButton
    @IBOutlet var zipCode: UILabel
    @IBOutlet var mapView: MKMapView
    @IBOutlet var message: UILabel
    @IBOutlet var exploreHint: UILabel
    
    enum Mode: Int {
        case Explore = 0
        case Search = 1
        case Locate = 2
    }
        
    let zipCodeFinder = ZipCodeFinder()
    
    var locationManager: CLLocationManager
    var latestLocation: CLLocation?
    var mode = Mode.Explore
    
    init(coder aDecoder: NSCoder!) {
        self.locationManager = CLLocationManager()
        super.init(coder: aDecoder)
    }
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        self.locationManager  = CLLocationManager()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        clearMessage()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone

        locationManager.startMonitoringSignificantLocationChanges()
        
        changeMode(Mode.Explore)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func findMe() {
        searchField.endEditing(true);
        
        if let coords = latestLocation?.coordinate {
           zipCodeFinder.findZipCode(forCoordinate: coords, onSuccess: setNewZipCode, onError: displayError)
        }
    }
    
    @IBAction func changeMode(sender: UISegmentedControl) {
        changeMode(Mode.fromRaw(sender.selectedSegmentIndex)!)
    }
    
    func changeMode(newMode: Mode) {
        switch newMode {
        case .Search:
            searchField.hidden = false
            exploreHint.hidden = true
            findBtn.hidden = true
        case .Explore:
            searchField.hidden = true
            exploreHint.hidden = false
            findBtn.hidden = true
        default:
            searchField.hidden = true
            exploreHint.hidden = true
            findBtn.hidden = false
        }
        
        mode = newMode
    }
    
    func setNewZipCode(newZipCode: String) {
        // Plan: animate text as it increments/decrements to new zip
        if newZipCode == zipCode.text {
            animateMessage("You're in the same zip code!")
        } else {
            let start = zipCode.text.toInt()
            let end = newZipCode.toInt()
            
            if start && end {
                let period = PRTweenPeriod.periodWithStartValue(CGFloat(start!), endValue: CGFloat(end!), duration: 0.5) as PRTweenPeriod
                
                PRTween.sharedInstance().addTweenPeriod(period, updateBlock: { (p: PRTweenPeriod!) in
                        self.zipCode.text = "\(Int(p.tweenedValue))"
                    }, completionBlock: nil)
            } else {
                zipCode.text = newZipCode
            }
            
            clearMessage()
        }
        
        if let coords = zipCodeFinder.latestCoordinates {
            if mode != .Explore {
                mapView.setRegion(MKCoordinateRegionMake(coords, MKCoordinateSpanMake(0.05, 0.05)), animated: true)
            }
        }
    }
    
    func displayError(error: String?) {
        zipCode.text = "!!!!!"
        
        if error {
            animateMessage(error!)
        }
    }
    
    func animateMessage(newMessage: String) {
        message.text = newMessage
        PRTween.tween(message, property: "alpha", from: 0.0, to: 1.0, duration: 2.0)
//        message.alpha = 0.0
//        
//        UIView.beginAnimations(nil, context: nil)
//        UIView.setAnimationCurve(UIViewAnimationCurve.EaseOut)
//        UIView.setAnimationDuration(2.0)
//        
//        message.alpha = 1.0
//        
//        UIView.commitAnimations()
    }
    
    func clearMessage() {
        message.text = ""
    }
    
    // Location manager delegate methods
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]) {
        let possibleNew = locations[locations.endIndex - 1] as CLLocation
        let newDate = possibleNew.timestamp
        
        if let oldDate = latestLocation?.timestamp {
            if newDate.compare(oldDate) == NSComparisonResult.OrderedDescending {
                latestLocation = possibleNew
            }
        } else {
            latestLocation = possibleNew
        }
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
        if !textField.text.isEmpty {
            zipCodeFinder.findZipCode(forCityName: textField.text, onSuccess: setNewZipCode, onError: displayError)
        }
    }
    
    // Map view delegate methods
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        if mode == .Explore {
            zipCodeFinder.findZipCode(forCoordinate: mapView.centerCoordinate,
                onSuccess: setNewZipCode, onError: displayError)
        }
    }
}