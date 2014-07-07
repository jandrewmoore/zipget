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

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate, UITabBarDelegate {
                            
    @IBOutlet var searchField: UITextField
    @IBOutlet var zipCode: UILabel
    @IBOutlet var mapView: MKMapView
    @IBOutlet var message: UILabel
    @IBOutlet var exploreHint: UILabel
    @IBOutlet var tabBar: UITabBar
    
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
        
        tabBar.selectedItem = tabBar.items[0] as UITabBarItem
        changeMode(Mode.Explore)
        
        registerForKeyboardNotifications()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func findMe() {
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
        case .Explore:
            searchField.hidden = true
            exploreHint.hidden = false
        default:
            searchField.hidden = true
            exploreHint.hidden = true
        }
        
        mode = newMode
        tabBar.selectedItem = tabBar.items[mode.toRaw()] as UITabBarItem
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
    }
    
    func clearMessage() {
        message.text = ""
    }
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let kbSize = info[UIKeyboardFrameBeginUserInfoKey].CGRectValue()
        let oldFrame = searchField.frame
        let newFrame = CGRectMake(oldFrame.origin.x, oldFrame.origin.y - kbSize.height + 49, oldFrame.width, oldFrame.height)
        
        let period = PRTweenPeriod.periodWithStartValue(oldFrame.origin.y, endValue: newFrame.origin.y, duration: 0.25) as PRTweenPeriod
        
        PRTween.sharedInstance().addTweenPeriod(period, updateBlock: { (p: PRTweenPeriod!) in
                self.searchField.frame.origin.y = p.tweenedValue
            }, completionBlock: nil)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let period = PRTweenPeriod.periodWithStartValue(searchField.frame.origin.y, endValue: 478, duration: 0.25) as PRTweenPeriod
        
        PRTween.sharedInstance().addTweenPeriod(period, updateBlock: { (p: PRTweenPeriod!) in
            self.searchField.frame.origin.y = p.tweenedValue
            }, completionBlock: nil)
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
        
        if !animated && mode != .Explore {
            changeMode(.Explore)
        }
    }
    
    // Tab bar delegate methods
    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        changeMode(Mode.fromRaw(item.tag)!)
        
        if item.tag == Mode.Locate.toRaw() {
            findMe()
        }
    }
}