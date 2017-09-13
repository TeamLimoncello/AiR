//
//  CreateFlightViewController.swift
//  AiR
//
//  Created by Brendon Warwick on 13/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

class CreateFlight: UIViewController, UITextFieldDelegate {
    // MARK: - Outlets
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var createFlightTitle: UILabel!
    @IBOutlet weak var flightNoTextField: UITextField!
    @IBOutlet weak var flightTimePicker: UIDatePicker!
    @IBOutlet weak var createFlightParentView: UIView!
    @IBOutlet weak var createFlightButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var flightNo: String!
    var flightDate: Date!
    
    // MARK: - Initialization
    override func viewDidLoad() {
        initialStyle()
    }
    
    func initialStyle(){
        parentView.layer.cornerRadius = 16
        parentView.addShadow(intensity: .Weak)
        createFlightParentView.layer.cornerRadius = 8
    }
    
    // MARK: - Text Field
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        flightNo = textField.text
    }
    
    @IBAction func dateChanged(_ sender: Any) {
        flightDate = flightTimePicker.date
    }
    
    // MARK: - Actions
    
    @IBAction func createFlightClicked(_ sender: Any) {
        if flightNo?.count == 6 || flightNo?.count == 7 {
            AiRServer.CreateFlight(flightNumber: flightNo, flightTime: flightDate) { s in
                if s! {
                    
                } else {
                    
                }
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
