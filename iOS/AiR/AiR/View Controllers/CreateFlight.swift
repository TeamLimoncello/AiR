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
    var flightDate = Date()

    // MARK: - Initialization
    override func viewDidLoad() {
        flightNoTextField.delegate = self
        initialStyle()
    }

    func initialStyle(){
        parentView.layer.cornerRadius = 16
        parentView.addShadow(intensity: .Weak)
        createFlightParentView.layer.cornerRadius = 8
    }

    // MARK: - Text Field

    func textFieldDidBeginEditing(_ textField: UITextField) {
        flightNo = textField.text
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        flightNo = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    @IBAction func dateChanged(_ sender: Any) {
        flightDate = flightTimePicker.date
        print("New Date: \(flightDate)")
    }

    // MARK: - Actions

    @IBAction func createFlightClicked(_ sender: Any) {
        if map(regex: "([A-Z]{3})([0-9]{1,4})([A-Za-z]?)", to: flightNo) {
            Server.shared.CreateFlight(flightNumber: flightNo, flightTime: flightDate) { (success, payload) in
                if success {
                    print("Successfully created flight with ID \(String(describing: payload))")

                    DispatchQueue.main.async {
                        Timer.scheduledTimer(withTimeInterval: 32, repeats: false, block: { (_) in
                            self.getData(withID: payload)
                        })
                    }

                } else {
                    print("Could not create flight, error: \(String(describing: payload))")
                    createDialogue(title: "Could not create flight", message: payload, parentViewController: self, dismissOnCompletion: false)
                }
            }
        } else {
            createDialogue(title: "Could not create flight", message: "Please enter a valid flight number", parentViewController: self, dismissOnCompletion: false)
        }
    }

    func getData(withID id : String){
        Server.shared.FetchData(id: id) { (data, error) in
            guard error == nil else {
                createDialogue(title: "Error getting data for this flight", message: error!, parentViewController: self, dismissOnCompletion: false)
                return
            }

            //Persists the flightPath in the IDs
            if var existing = UserDefaults.standard.array(forKey: "flightPaths") {
                existing.append(id)
                UserDefaults.standard.set(existing, forKey: "flightPaths")
            } else {
                UserDefaults.standard.set([id], forKey: "flightPaths")
            }

            createDialogue(title: "Flight Successfully Created!", message: "Now you just have to launch AiR on the day of your flight.", parentViewController: self, dismissOnCompletion: true)
        }
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
