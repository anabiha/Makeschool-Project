//
//  ViewController.swift
//  PhotoApp
//
//  Created by Ayesha Nabiha on 7/26/18.
//  Copyright © 2018 Ayesha Nabiha. All rights reserved.
//

import UIKit
import Clarifai

class ViewController: UIViewController {
    
    var app = ClarifaiApp(apiKey: "b3780911900f448ab1f30a9dc4171787")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    func getPrediction() {
        model = app?.getModels(<#T##page: Int32##Int32#>, resultsPerPage: <#T##Int32#>, completion: <#T##ClarifaiModelsCompletion!##ClarifaiModelsCompletion!##([ClarifaiModel]?, Error?) -> Void#>)
        
    }




}

