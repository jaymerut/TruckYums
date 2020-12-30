//
//  FindFoodTrucksViewController.swift
//  FoodTruckCompany
//
//  Created by Jayme Rutkoski on 11/26/20.
//  Copyright © 2020 foodtruckcompany. All rights reserved.
//

import UIKit
import SnapKit
import MapKit
import CoreLocation


class FindFoodTrucksViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    // MARK: - Variables
    public var companies: [String: Company] = [:]
    
    let distanceSpan: Double = 50
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView.init(frame: .zero)
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsScale = true
        mapView.showsCompass = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        return mapView
    }()
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        
        return manager
    }()
    private lazy var firebaseCloudRead: FirebaseCloudRead = {
        let firebaseCloudRead = FirebaseCloudRead.init()
        
        return firebaseCloudRead
    }()
    private lazy var queryHelper: QueryHelper = {
        let helper = QueryHelper()
        
        return helper
    }()
    private lazy var dateTimeHelper: DateTimeHelper = {
        let helper = DateTimeHelper()
        
        return helper
    }()
    private lazy var mkPOICategoryHelper: MKPointOfInterestCategoryHelper = {
        let helper = MKPointOfInterestCategoryHelper()
        
        return helper
    }()
    
    // MARK: - Initialization
    private func customInitFindFoodTrucksViewController() {
        
    }
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        
        customInitFindFoodTrucksViewController()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        customInitFindFoodTrucksViewController()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        customInitFindFoodTrucksViewController()
    }
    
    
    
    // MARK: - UIViewController Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.firebaseCloudRead.firebaseReadCompanies { (companies) in
            for company in companies ?? [Company]() {
                self.companies[company.name] = company
            }
            self.getUserCoordinates()
        }
        
        // Setup
        setupFindFoodTrucksViewController()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    
    // MARK: - Private API
    private func setupFindFoodTrucksViewController() {
        
        self.view.addSubview(self.mapView)
        self.mapView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
    }
    private func getUserCoordinates() {
        self.locationManager.requestWhenInUseAuthorization()
        
        self.locationManager.startUpdatingLocation()
    }
    /*
    private func getCompanyFromName(name: String) -> Company {
        for company: Company in self.companies {
            if company.name == name {
                return company
            }
        }
        return Company.init(name: "", latitude: 0, longitude: 0, linkedwith: "", venderverified: false, cuisine: "", phonenumber: "", siteurl: "", lastupdated: "", hours: "")
    }
 */
    
    // MARK: Navigation Logic
    private func navigateToCompanyDetail(company: String) {
        let destinationVC = CompanyDetailViewController.init()
        destinationVC.modalPresentationStyle = .overFullScreen
        destinationVC.modalTransitionStyle = .crossDissolve
        destinationVC.company = self.companies[company] ?? Company()
        
        self.present(destinationVC, animated: true, completion: nil)
    }
    
    // MARK: Delegate Methods
    
    // CLLocation Delegate Methods
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        let region = MKCoordinateRegion.init(center: newLocation.coordinate, latitudinalMeters: self.distanceSpan, longitudinalMeters: self.distanceSpan)
        self.mapView.setRegion(region, animated: false)
        self.mapView.showsUserLocation = true
        }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        let currentLocation:CLLocation = locations.last ?? CLLocation.init()
        let region = MKCoordinateRegion(
              center: currentLocation.coordinate,
              latitudinalMeters: 50000,
              longitudinalMeters: 60000)
        
        
        self.queryHelper.searchBy(naturalLanguageQuery: "food truck", region: region, coordinates: locValue) { (response, error) in
            
            for mapItem in response?.mapItems ?? [MKMapItem]() {
                let company = Company()
                company.name = mapItem.name ?? ""
                company.phonenumber = mapItem.phoneNumber ?? ""
                company.siteurl = mapItem.url?.absoluteString ?? ""
                company.longitude = mapItem.placemark.coordinate.longitude
                company.latitude = mapItem.placemark.coordinate.latitude
                company.cuisine = self.mkPOICategoryHelper.convertRawValueToStringValue(rawValue: mapItem.pointOfInterestCategory?.rawValue ?? "")
                company.venderverified = false
                company.lastupdated = self.dateTimeHelper.retrieveCurrentDateTime()
                
                let keyExists = self.companies[company.name]
                if (keyExists == nil) {
                    self.companies[company.name] = company
                }
            }
            
            for (key, value) in self.companies {
                let annotation = MKPointAnnotation()
                annotation.title = key
                annotation.coordinate = CLLocationCoordinate2D(latitude: value.latitude, longitude: value.longitude)
                self.mapView.addAnnotation(annotation)
            }
            
            let mapCamera = MKMapCamera(lookingAtCenter: locValue, fromEyeCoordinate: locValue, eyeAltitude: 15000)
            self.mapView.setCamera(mapCamera, animated: true)
            
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    // MKMapView Delegate Methods
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if (view.annotation?.title ?? "")?.count ?? 0 > 0 && (view.annotation?.title ?? "") != "My Location" {
            self.navigateToCompanyDetail(company: (view.annotation?.title ?? "") ?? "")
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation.title == "My Location") {
            return nil
        }
        let reuseId = "test"

        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView?.canShowCallout = true
        }
        else {
            anView?.annotation = annotation
        }

        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...

        anView?.image = UIImage(named:"image_annotation")

        return anView
    }
    
    // MARK: - Public API
    
    
    
}
