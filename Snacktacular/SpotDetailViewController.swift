//
//  SpotDetailViewController.swift
//  Snacktacular
//
//  Created by John Pappas on 11/1/20.
//  Copyright © 2020 John Pappas. All rights reserved.
//

import UIKit
import GooglePlaces
import MapKit
import Contacts

class SpotDetailViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tablewView: UITableView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    var spot: Spot!
    let regionDistance: CLLocationDegrees = 750.0
    var locationManager: CLLocationManager!
    var reviews: Reviews!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        tablewView.delegate = self
        tablewView.dataSource = self
        
        getLocation()
        if spot == nil {
            spot = Spot()
        } else {
            disableTextEditing()
            cancelBarButton.hide()
            saveBarButton.hide()
            navigationController?.setToolbarHidden(true, animated: true)
        }
        
        setupMapView()
        reviews = Reviews()
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reviews.loadData(spot: spot) {
            self.tablewView.reloadData()
        }
    }
    
    func disableTextEditing() {
        nameTextField.isEnabled = false
        addressTextField.isEnabled = false
        nameTextField.backgroundColor = .clear
        addressTextField.backgroundColor = .clear
        nameTextField.borderStyle = .none
        addressTextField.borderStyle = .none
    }
    
    func setupMapView() {
        let region = MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        mapView.setRegion(region, animated: true)
    }
    
    func updateUserInterface() {
        nameTextField.text = spot.name
        addressTextField.text = spot.address
        updateMap()
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(spot)
        mapView.setCenter(spot.coordinate, animated: true)
    }
    
    func updateFromInterface() {
        spot.name = nameTextField.text!
        spot.address = addressTextField.text!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateFromInterface()
        switch segue.identifier ?? "" {
        case "AddReview":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ReviewTableViewController
            destination.spot = spot
        case "ShowReview":
            let destination = segue.destination as! ReviewTableViewController
            let selectedIndexPath = tablewView.indexPathForSelectedRow!
            destination.review = reviews.reviewArray[selectedIndexPath.row]
            destination.spot = spot
        case "AddPhoto":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! PhotoViewController
            destination.spot = spot
        case "ShowPhoto":
            let destination = segue.destination as! PhotoViewController
            destination.spot = spot
        default:
            print("couldnt find a case")
        }
    }
    
    func saveCancelAlert(title: String, message: String, sequeIdentifier: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            self.spot.saveData { (sucess) in
                self.saveBarButton.title = "Done"
                self.cancelBarButton.hide()
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.disableTextEditing()
                self.performSegue(withIdentifier: sequeIdentifier, sender: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion:  nil)
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func nameFieldChanged(_ sender: UITextField) {
        let noSpaces = nameTextField.text!.trimmingCharacters(in: .whitespaces)
        if noSpaces != "" {
            saveBarButton.isEnabled = true
        } else {
            saveBarButton.isEnabled = false
        }
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        updateFromInterface()
        spot.saveData { (success) in
            if success {
                self.leaveViewController()
            } else {
                self.oneButtonAlert(title: "Save Failed", message: "Data would not save to cloud.")
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    @IBAction func lookupButtonPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func ratingButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This venue has not been saved.", message: "You must save this venue before you can review it", sequeIdentifier: "AddReview")
        } else {
            
        }
        performSegue(withIdentifier: "AddReview", sender: nil)
    }
    
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This venue has not been saved.", message: "You must save this venue before you can review it", sequeIdentifier: "AddPhoto")
        } else {
            
        }
        performSegue(withIdentifier: "AddPhoto", sender: nil)
    }
    
}

extension SpotDetailViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        spot.name = place.name ?? "Unknown Place"
        spot.address = place.formattedAddress ?? "Unknown Address"
        spot.coordinate = place.coordinate
        updateUserInterface()
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension SpotDetailViewController: CLLocationManagerDelegate {
    
    func getLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("checking auth. status")
        handleAuthenticationStatus(status: status)
    }
    
    func handleAuthenticationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            self.oneButtonAlert(title: "location services denied", message: "parental controls resricting access?")
        case .denied:
            showAlertToPrivacySettings(title: "User has not authorized location services", message: "Select 'Settings' below to enable device settings and enable location services for this app")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            print("unknown case of status handleAuthenticationStatus\(status)")
        }
    }
    
    func showAlertToPrivacySettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            print("Something went wrong")
            return
        }
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let currentLocation = locations.last ?? CLLocation()
        print("updating location is \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        var name = ""
        var address = ""
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            if error != nil {
                print("error: \(error!.localizedDescription)")
            }
            if placemarks != nil {
                let placemark = placemarks?.last
                name = placemark?.name ?? "Name Unknown"
                if let postalAddress = placemark?.postalAddress {
                    address = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                }
            } else {
                print("error: retrieving placemark")
            }
            if self.spot.name == "" && self.spot.address == "" {
                self.spot.name = name
                self.spot.address = address
                self.spot.coordinate = currentLocation.coordinate
            }
            self.mapView.userLocation.title = name
            self.mapView.userLocation.subtitle = address.replacingOccurrences(of: "\n", with: ", ")
            self.updateUserInterface()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR: \(error.localizedDescription), failed to get device loaction")
    }
}

extension SpotDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.reviewArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as! SpotReviewTableViewCell
        cell.review = reviews.reviewArray[indexPath.row]
        return cell
    }
}
