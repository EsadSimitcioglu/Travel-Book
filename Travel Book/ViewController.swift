//
//  ViewController.swift
//  Travel Book
//
//  Created by Esat Simitcioglu on 17.06.2020.
//  Copyright © 2020 Esat Simitcioglu. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController ,MKMapViewDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var subTitleText: UITextField!
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleId : UUID?
    
    var anotationTitle = ""
    var anotationSubtitle = ""
    var anotationLatitude = Double()
    var anotationLongitude = Double()
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if selectedTitle == ""{
            navigationBar.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.save, target: self, action: #selector(saveButtonClicked))
        }
    
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(setPin(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        
        if selectedTitle != "" {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Landmarks")
            let idString = selectedTitleId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0 {
                    
                    for result in results as! [NSManagedObject]{
                    
                        if let title = result.value(forKey: "title") as? String {
                            anotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                anotationSubtitle = subtitle
                                if let latitude = result.value(forKey: "latitude") as? Double{
                                    anotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                         anotationLongitude = longitude
                                        
                                        let anotation = MKPointAnnotation()
                                        anotation.title = anotationTitle
                                        anotation.subtitle = anotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: anotationLatitude, longitude: anotationLongitude)
                                        anotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(anotation)
                                        titleText.text = anotationTitle
                                        subTitleText.text = anotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                
            }catch{
                print("Error at CoreData")
            }
            
            
        }
    
        
    }
    
    @objc func saveButtonClicked(){
       
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newLandmarks = NSEntityDescription.insertNewObject(forEntityName: "Landmarks", into: context)
        
        newLandmarks.setValue(titleText.text, forKey: "title")
        newLandmarks.setValue(subTitleText.text, forKey: "subtitle")
        newLandmarks.setValue(chosenLongitude, forKey: "longitude")
        newLandmarks.setValue(chosenLatitude, forKey: "latitude")
        newLandmarks.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
        }catch{
            print("Error at saveButtonClicked")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newLandmark"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func setPin(gestureRecognizer: UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began{
            
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
                
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = titleText.text
            annotation.subtitle = subTitleText.text
            mapView.addAnnotation(annotation)
            
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05 , longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let ID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: ID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.green
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }
        else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != "" {
            
            let newLocation = CLLocation(latitude: anotationLatitude, longitude: anotationLongitude)
            CLGeocoder().reverseGeocodeLocation(newLocation) { (landmarks, error) in
                if let landmark = landmarks{
                if landmark.count > 0 {
                    let newLandmark = MKPlacemark(placemark: landmark[0])
                    let item = MKMapItem(placemark: newLandmark)
                    item.name = self.anotationTitle
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
            }
        }
    }


}

