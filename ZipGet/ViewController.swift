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

class ViewController: UIViewController {
                            
    @IBOutlet var searchField: UITextField!
    @IBOutlet var zipCode: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var message: UILabel!
    @IBOutlet var exploreHint: UILabel!
    @IBOutlet var tabBar: UITabBar!
    
    enum Mode: Int {
        case Explore = 0
        case Search = 1
        case Locate = 2
    }
    
    var zipCodeFinder: ZipCodeFinder?
    
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
        
        clearMessage()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        tabBar.selectedItem = tabBar.items[0] as UITabBarItem
        changeMode(Mode.Explore)
        
        registerForKeyboardNotifications()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "appDidBecomeActive:",
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "appWillResignActive:",
            name: UIApplicationWillResignActiveNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification,
            object: nil)
    }
    
    func appDidBecomeActive(notification: NSNotification) {
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func appWillResignActive(notification: NSNotification) {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func userDefaultsDidChange(notification: NSNotification) {
        let defaults = notification.object as NSUserDefaults
        let username = defaults.stringForKey("username_preference")
        
        if username.isEmpty {
            zipCodeFinder = nil
        } else {
            zipCodeFinder = ZipCodeFinder(username)
        }
    }
    
    func findMe() {
        if let coords = latestLocation?.coordinate {
            if !zipCodeFinder {
                setUpZipCodeFinder()
            }
            zipCodeFinder?.findZipCode(forCoordinate: coords, onSuccess: setNewZipCode, onError: displayError)
        }
    }
    
    func changeMode(sender: UISegmentedControl) {
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
        if newZipCode == zipCode.text {
            animateMessage("You're in the same zip code!")
        } else {
            let start = zipCode.text.toInt()
            let end = newZipCode.toInt()
            
            if start && end {
                let period = PRTweenPeriod.periodWithStartValue(CGFloat(start!), endValue: CGFloat(end!), duration: 0.5) as PRTweenPeriod
                
                PRTween.sharedInstance().addTweenPeriod(period, updateBlock: { (p: PRTweenPeriod!) in
                    if p.tweenedValue < 10000 {
                        self.zipCode.text = "0\(Int(p.tweenedValue))"
                    } else {
                        self.zipCode.text = "\(Int(p.tweenedValue))"
                    }
                    }, completionBlock: { self.zipCode.text = newZipCode })
            } else {
                zipCode.text = newZipCode
            }
            
            clearMessage()
        }
        
        if let coords = zipCodeFinder?.latestCoordinates {
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
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo as [String:AnyObject]
        let kbSize = info[UIKeyboardFrameBeginUserInfoKey]!.CGRectValue()
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
    
    func setUpZipCodeFinder() {
        let newUsername = NSUserDefaults.standardUserDefaults().stringForKey("username_preference")
        if newUsername.isEmpty {
            let usernameAlert = UIAlertView()
            usernameAlert.title = "Who are you?"
            usernameAlert.message = "The GeoNames service ZipGet uses requires a username. Get one at geonames.org."
            usernameAlert.delegate = self
            usernameAlert.addButtonWithTitle("Forget it")
            usernameAlert.addButtonWithTitle("Sign in")
            usernameAlert.addButtonWithTitle("Go register")
            usernameAlert.alertViewStyle = UIAlertViewStyle.PlainTextInput
            
            usernameAlert.show()
        } else {
            zipCodeFinder = ZipCodeFinder(newUsername)
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]) {
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
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField!) {
        if !textField.text.isEmpty {
            if !zipCodeFinder {
                setUpZipCodeFinder()
            }
            zipCodeFinder?.findZipCode(forCityName: textField.text, onSuccess: setNewZipCode, onError: displayError)
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        if mode == .Explore {
            if !zipCodeFinder {
                setUpZipCodeFinder()
            }
            
            zipCodeFinder?.findZipCode(forCoordinate: mapView.centerCoordinate,
                onSuccess: setNewZipCode, onError: displayError)
        }
        
        if !animated && mode != .Explore {
            changeMode(.Explore)
        }
    }
}

extension ViewController: UITabBarDelegate {
    func tabBar(tabBar: UITabBar!, didSelectItem item: UITabBarItem!) {
        changeMode(Mode.fromRaw(item.tag)!)
        
        if item.tag == Mode.Locate.toRaw() {
            findMe()
        }
    }
}

extension ViewController: UIAlertViewDelegate {
    func alertViewShouldEnableFirstOtherButton(alertView: UIAlertView!) -> Bool {
        return !alertView.textFieldAtIndex(0).text.isEmpty
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            let username = alertView.textFieldAtIndex(0).text
            if !username.isEmpty {
                zipCodeFinder = ZipCodeFinder(username)
                NSUserDefaults.standardUserDefaults().setValue(username, forKey:"username_preference")
            }
        }
        
        if buttonIndex == 2 {
            // Go to safari
            let url = NSURL(string: "http://www.geonames.org/login")
            UIApplication.sharedApplication().openURL(url)
        }
        
    }
}