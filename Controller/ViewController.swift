//
//  ViewController.swift
//  PhotoApp
//
//  Created by Ayesha Nabiha on 7/26/18.
//  Copyright © 2018 Ayesha Nabiha. All rights reserved.
//

import UIKit
import Clarifai
import Alamofire
import SwiftyJSON
import GooglePlaces
import GooglePlacePicker

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var locationView: UITextView!
    
    var app: ClarifaiApp?
    var placesClient: GMSPlacesClient!
    var tags : [String] = []
    let locationManager = CLLocationManager()
    
    //this array holds "clean" tags that can be searchble in the google maps api
    var cleanTags =  ["park", "beach", "restaurant", "hotel", "bar", "coffee", "food", "landmark", "museum", "garden", "vineyard", "bridge", "concert", "cathedral", "religion", "tourism", "tower", "mountain", "historic sites", "shopping", "boutique", "nature"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        app = ClarifaiApp(apiKey: "b3780911900f448ab1f30a9dc4171787")
        
        placesClient = GMSPlacesClient.shared()
        
        
        locationManager.delegate = self as? CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        //show a UIImagePickerController to let the user pick an image from their library
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let picker = UIImagePickerController()
            picker.allowsEditing = false
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //after the user picks an image, send it to Clarifai for recognition
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
            recognizeImage(image: image)
            for tag in tags {
                print(tag) //prints to console
            }
            textView.text = "Recognizing..."
            button.isEnabled = false
        }
    }
    
    func makeSearch() {
        for tag in tags {
            //searchWithTag(keyword: tag) { (image, url) in
           //     self.imageView.image = image
           // }
            for cleanTag in cleanTags {
                if cleanTag.contains(tag) {
                    print("this picture contains \(cleanTag)")
                }
            }
        }
       
    }
    
    //gets the current place of the user
    func getCurrentPlace() {
        placesClient.currentPlace { (placeLikelihoodList, error) in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            self.locationView.text = ""
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.locationView.text = place.name + "  " + (place.formattedAddress?.components(separatedBy: ", ").joined(separator: "\n"))!
                }
            }
        }
        
    }
    
    func recognizeImage(image: UIImage) {
        //check that the app was initialized correctly
        if let app = app {
            //fetch Clarifai's general model
            app.getModelByName("general-v1.3", completion: { (model, error) in
                //create a Clarifai image from a uimage
                let caiImage = ClarifaiImage(image: image)!
                //use Clarifai's general model to predict tags for a given image
                model?.predict(on: [caiImage], completion: { (outputs, error) in
                    print("%@", error ?? "no error")
                    guard let caiOutputs = outputs else {
                        print("Predict failed")
                        return
                    }
                    if let caiOutput = caiOutputs.first {
                        //loop through predicted concepts (tags) and display them on the screen
                        for concept in caiOutput.concepts {
                            self.tags.append(concept.conceptName)
                            //TO DO: maybe create a dictionary with the tag and its score??
                        }
                        print(self.tags)
                        DispatchQueue.main.async {
                            //update the new tags in the UI
                            self.textView.text = "Tags: "
                            for tag in self.tags {
                            self.textView.text.append(", \(tag)")
                            }
                            //self.textView.text = String(format: "Tags:\n%@", self.tags.componentsJoined(by: ", "))
                        }
                        DispatchQueue.main.async {
                            //reset select photo button for multiple selections
                            self.button.isEnabled = true
                            //for each tag, find a corresponding picture
                           //for tag in self.tags {
                          //  self.searchWithTag(keyword: self.tags.first!, completion: { (image, url) in
                                  //  self.imageView.image = image
                              //  })
                            //}
                            self.findPlace(input: self.cleanTags.first!, completion: { (image, url) in
                                self.imageView.image = image
                            })
                            //self.makeSearch()
                            self.getCurrentPlace()
                            self.tags.removeAll()
                        }

                    }
                })
            })
        }
    }
    
    func findPlace(input: String, completion: @escaping(UIImage, String) -> Void) {

        let strUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522,151.1957362&radius=1500&type=\(input)&keyword=\(input)&key=AIzaSyA0anuwocMn289O95ScN1TnQ0Fwv68PbJk"
      
        Alamofire.request(strUrl).responseJSON { (response) in
            if response.result.isSuccess {
                let searchResult : JSON = JSON(response.result.value!)
                //TO DO: handle place not found
                let imageResult = searchResult["results"][0]["icon"].string!
                Alamofire.request(imageResult).responseData(completionHandler: { (response) in
                    if response.result.isSuccess {
                        let image = UIImage(data: response.result.value!)
                        completion(image!, imageResult)
                    } else {
                        print("Image Load Failed! \(response.result.error ?? "error" as! Error)")
                    }
                })
            } else {
                print("Google Maps Search Failed! \(response.result.error ?? "error" as! Error)")
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location:: (location)")
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: (error)")
    }
}


