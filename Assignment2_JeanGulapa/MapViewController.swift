//
//  MapViewController.swift
//  Assignment2_JeanGulapa
//
//  Created by Jean on 2019-10-18.
// Email: gulapaj@sheridancollege.ca
//  Copyright © 2019 Jean. All rights reserved.
//
//This Controller handles the map view

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, RouteViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    let locationManager = CLLocationManager()
    var currLocation: CLLocation?
    var destination: CLLocation?
    var source: CLLocation?
    let geocoder = CLGeocoder()
    var compass = MKCompassButton()
    var mapItems : [MKRoute] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set delegate for mapview
        self.map.delegate = self
        
        // set usage of corelocationmanager
        locationManager.requestWhenInUseAuthorization()
        
        // get the current location only if location service is enabled
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
        
        //adds compass
        map.showsCompass = false  // Hide built-in compass
        compass = MKCompassButton(mapView: map)
        compass.compassVisibility = .visible
        
        map.addSubview(compass) // Add it to the view
        
        compass.translatesAutoresizingMaskIntoConstraints = false
        compass.trailingAnchor.constraint(equalTo: map.trailingAnchor, constant: -12).isActive = true
        compass.topAnchor.constraint(equalTo: map.topAnchor, constant: 12).isActive = true
        
        //adds scale
        let scale = MKScaleView(mapView: map)
        scale.scaleVisibility = .visible // always visible
        view.addSubview(scale)
        
        // Enable heading tracking mode so that the arrow will appear.
        self.map.userTrackingMode = .followWithHeading
    }
    
    
    //gets the returned values
    func routeViewDidFinish(sender: RouteViewController, data: Int) {
        
        //removes the current overlays
        map.removeOverlays(map.overlays)
        
        mapItems = sender.mapItems
        
        self.destination = sender.destination
        self.source = sender.source
        let toAddress = sender.toAddress.text
        let fromAddress = sender.fromAddress.text
        
        self.map.addOverlay(mapItems[data].polyline, level: MKOverlayLevel.aboveRoads)
        self.map.setVisibleMapRect(mapItems[data].polyline.boundingMapRect, animated:true)
        
        if(sender.fromAddress.text == "") {
            
            // add pin annotation
            let pin = MKPointAnnotation()
            pin.coordinate = destination?.coordinate ?? CLLocationCoordinate2D(latitude: 0,longitude: 0)
            pin.title = toAddress
            self.map.addAnnotation(pin)
            
        }else{
            // add pin annotation for destination
            let pinTo = MKPointAnnotation()
            pinTo.coordinate = destination?.coordinate ?? CLLocationCoordinate2D(latitude: 0,longitude: 0)
            pinTo.title = fromAddress
            self.map.addAnnotation(pinTo)
            
            //add pin annotation for source
            let pinFrom = MKPointAnnotation()
            pinFrom.coordinate = source?.coordinate ?? CLLocationCoordinate2D(latitude: 0,longitude: 0)
            pinFrom.title = toAddress
            self.map.addAnnotation(pinFrom)
        }
    }
    
    func locationManager(_ manager:CLLocationManager,didUpdateLocations locations:[CLLocation]) {
        //check if first time
        if let location = locations.last {
            if currLocation == nil{
                //first time, set region
                let center = location.coordinate
                //for 500m
                let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
                self.map.setRegion(region, animated: true)
            }
            //constantly remember user location
            currLocation = location
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueRoute"
        {
            if let vc = segue.destination as? RouteViewController
            {
                vc.currentLocation = self.currLocation ?? CLLocation(latitude:43.468975, longitude:-79.69957)
                vc.delegate = self
                vc.destination = self.destination
                vc.mapItems = self.mapItems
            }
        }
        
    }
    
    func mapView(_ mapView:MKMapView,
                 rendererFor overlay:MKOverlay) -> MKOverlayRenderer
    {
        // if overlay is polyline, return MKPolylineRenderer
        if let polyline = overlay as? MKPolyline
        {
            let renderer = MKPolylineRenderer(polyline:polyline)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer(overlay:overlay)
    }
    
    //function for the segment that allows the user to change the map type
    @IBAction func segmentedControlAction(sender: UISegmentedControl!) {
        switch (sender.selectedSegmentIndex) {
        case 0:
            map.mapType = .standard
        case 1:
            map.mapType = .satellite
        default:
            map.mapType = .hybrid
        }
    }
}





