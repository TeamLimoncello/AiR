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
    var firstLoad = true
    
    // Nearest flight info, will be pulled from local storage
    let flightDestination = "San Francisco"
    let flightDate = "21st July at 9pm"
    let airplaneModeEnabled = true
    
    // MARK: - Initialization
    override func viewDidLoad() {
        initialStyle()
        apply(state: .FlightReady)
        
        // Set airplane mode indicator
        // statusIndicator.image = !SCNetworkReachabilityFlags.reachable ? #imageLiteral(resourceName: "Plane") : #imageLiteral(resourceName: "NoPlane")
    }
    
    override func viewDidLayoutSubviews() {
        if firstLoad {
            // Apply the gradient background
            let gradient = CAGradientLayer()
            gradient.frame = view.bounds
            gradient.colors = [UIColor.hexToRGB(hex: "BADAF8")!.cgColor, UIColor.hexToRGB(hex: "799FCF")!.cgColor]
            view.layer.insertSublayer(gradient, at: 0)
            parentView.backgroundColor = .clear
            firstLoad = false
        }
    }
    
    func initialStyle() {
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
            flightMgmtButtonsParentView.isHidden = true
            destinationLabel.text = "\(flightDestination)"
            dateLabel.text = "Ready to fly!"
            if airplaneModeEnabled {
                // Flight ready to experience!
                planeButton.isHidden = false
                planeButton.addShadow(intensity: .ChristianBale)
                experienceLabel.text = "Click the plane to experience AiR."
            } else {
                // Need airplane mode first
                experienceLabel.text = "Please enable airplane mode before using AiR."
            }
        case .UpcomingFlight:
            // Upcoming flight
            planeButton.isEnabled = false
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Make sure to enable airplane mode and have GPS turned on during your flight to experience AiR."
            destinationLabel.text = "\(flightDestination)"
            dateLabel.text = "\(flightDate)"
        default:
            // No flights setup
            planeButton.isHidden = true
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Add a flight to begin the AiR experience."
            destinationLabel.isHidden = true
            dateLabel.isHidden = true
            viewFlightsView.isHidden = true
        }
    }
}
