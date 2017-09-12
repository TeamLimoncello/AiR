//
//  IntroViewController.swift
//  AiR
//
//  Created by Brendon Warwick on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

class IntroViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var planeButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusIndicator: UIImageView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var experienceLabel: UILabel!
    @IBOutlet weak var flightMgmtButtonsParentView: UIView!
    @IBOutlet weak var createFlightView: UIView!
    @IBOutlet weak var createFlightButton: UIButton!
    @IBOutlet weak var viewFlightsView: UIView!
    @IBOutlet weak var viewFlightsButton: UIButton!
    
    // MARK: - Properties
    override var prefersStatusBarHidden: Bool { return true }
    enum AiRState {
        case NoFlights
        case UpcomingFlight
        case FlightReady
    }
    
    // MARK: - Initialization
    override func viewDidLoad() {
        initialStyle()
        apply(state: .NoFlights)
        
        // Set airplane mode indicator
        // START HEEEERRRREEEE 
        // statusIndicator.image = !SCNetworkReachabilityFlags.reachable ? #imageLiteral(resourceName: "Plane") : #imageLiteral(resourceName: "NoPlane")
    }
    
    func initialStyle() {
        // Apply the gradient background
        let gradient = CAGradientLayer()
        gradient.frame = parentView.bounds
        gradient.colors = [UIColor.hexToRGB(hex: "BADAF8")!.cgColor, UIColor.hexToRGB(hex: "799FCF")!.cgColor]
        parentView.layer.insertSublayer(gradient, at: 0)
        
        // Style Flight Management buttons
        flightMgmtButtonsParentView.backgroundColor = .clear
        createFlightView.layer.cornerRadius = 8
        createFlightView.addShadow(intensity: .Weak)
        viewFlightsView.layer.cornerRadius = 8
        viewFlightsView.addShadow(intensity: .Weak)
    }
    
    func apply(state: AiRState) {
        switch state {
        case .FlightReady:
            // Flight ready to experience!
            planeButton.isHidden = false
            planeButton.addShadow(intensity: .ChristianBale)
            flightMgmtButtonsParentView.isHidden = true
            experienceLabel.text = "Click the plane to experience AiR."
        case .UpcomingFlight:
            // Upcoming flight
            planeButton.isHidden = false
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Make sure to enable airplane mode and have GPS turned on during your flight to experience AiR."
        default:
            // No flights setup
            planeButton.isHidden = true
            flightMgmtButtonsParentView.isHidden = false
            viewFlightsView.alpha = 0.5
            viewFlightsButton.isEnabled = false
            experienceLabel.text = "Add a flight to begin the AiR experience."
        }
    }
    
    @IBAction func planeClicked(_ sender: Any) {
        
    }
}
