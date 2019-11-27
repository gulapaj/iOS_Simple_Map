//
//  RouteViewController.swift
//  Assignment2_JeanGulapa
//
//  Created by Jean on 2019-10-18.
// Email: gulapaj@sheridancollege.ca
//  Copyright © 2019 Jean. All rights reserved.
//
//This controller handles the routing conversion from a source to destination location and then into map controller

import UIKit
import CoreLocation
import MapKit

class RouteViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var fromAddress: UITextField!
    @IBOutlet weak var toAddress: UITextField!
    
    var currentLocation: CLLocation?
    var destination: CLLocation?
    var source: CLLocation?
    var delegate: RouteViewDelegate?
    var mapItems : [MKRoute] = []
    
    @IBOutlet var tblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        RouteBack(row)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapItems.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "RouteCell", for: indexPath)
        
        // Configure the cell...
        let row = indexPath.row
        let name = mapItems[row].name
        let distance = mapItems[row].distance
        let time = mapItems[row].expectedTravelTime
        
        //calls the time converter before displaying into table view
        let timeConverted = stringFromTimeInterval(interval: time)
        
        cell.textLabel?.text = "via \(String(describing: name)) E: \(String(describing: distance)), \(String(describing: timeConverted))"
        
        return cell
    }
    
    //converts time to HH:mm:ss
    func stringFromTimeInterval(interval: TimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
    func forwardGeocoding(address:String, completion: @escaping ((CLLocation?) -> Void)) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: { (placemarks, error) in
            if (error != nil) {
                let alertController = UIAlertController(title: "Warning!",message: "Please provide needed locations!" , preferredStyle: .alert)
                let confirm = UIAlertAction(title: "Confirm", style: .default, handler: nil)
                alertController.addAction(confirm)
                
                self.present(alertController, animated: true, completion: nil)
                completion(nil)
            }
            else {
                // found locations, then perform the next task using closure
                let placemark = placemarks?[0]
                completion(placemark?.location)
            }
        })
    }
    
    //function for the Route button
    @IBAction func HandleRouteBack(_ sender:Any) {
        
        //deletes the old routes
        mapItems.removeAll();
        
        let toAdd = toAddress.text ?? ""

        if(fromAddress.text == "") {
            forwardGeocoding(address: toAdd, completion: { (location) in
                if let locationTo = location {
                    // found destination, calculate routes
                    print(locationTo)
                    self.route(from:self.currentLocation ?? CLLocation(latitude: 0,longitude: 0), to:locationTo )
                    self.destination = locationTo
                }
                else { // not found destination, show alert
                    let alertController = UIAlertController(title: "Warning!", message: "Destination cannot be found. Please provide a valid 'To' location.", preferredStyle: .alert)
                    let confirm = UIAlertAction(title: "Confirm", style: .default, handler: nil)
                    alertController.addAction(confirm)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            })
        } else {
            let fromAdd = fromAddress.text ?? ""
            forwardGeocoding(address: fromAdd, completion: { (location) in
                if let locationFrom = location {
                    // found source, try to find destination next
                    self.forwardGeocoding(address:toAdd, completion: { (location) in
                        if let locationTo = location {
                            // found destination, calculate routes
                            self.route(from:locationFrom, to:locationTo)
                            self.destination = locationTo
                            self.source = locationFrom
                        }
                        else {
                        }
                    })
                }
                else {
                    let alertController = UIAlertController(title: "Warning!", message: "Current location cannot be found.  Please provide a valid 'From' location.", preferredStyle: .alert)
                    let confirm = UIAlertAction(title: "Confirm", style: .default, handler: nil)
                    alertController.addAction(confirm)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            })
        }
    }
    
    func route(from: CLLocation, to: CLLocation) {
        // request directions
        let request = MKDirections.Request()
        let fromPlacemark = MKPlacemark(coordinate: from.coordinate)
        let toPlacemark = MKPlacemark(coordinate: to.coordinate)
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        // calculate directions
        let directions = MKDirections(request: request);
        directions.calculate(completionHandler: { (response, error) in
            if let error = error {
                print(error);
                // show alert
                return }
            if let routes = response?.routes
            {
                for route in routes
                {
                    print("Name: " + route.name)
                    print("Distance: \(route.distance)")
                    print("Expected Travel Time: \(route.expectedTravelTime)")
                    
                    self.mapItems.append(route)
                }
                self.tblView.reloadData()
            }
        })
    }
    
    func RouteBack(_ sender: Int) {
        delegate?.routeViewDidFinish(sender:self, data: sender)
        dismiss(animated:true, completion:nil)
        
    }
}

protocol RouteViewDelegate: AnyObject {
    func routeViewDidFinish(sender:RouteViewController, data: Int)
}
