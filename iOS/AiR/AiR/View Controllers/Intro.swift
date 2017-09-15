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

class Intro: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var planeButton: UIButton!
    @IBOutlet weak var planeHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var planeTopConstraint: NSLayoutConstraint!
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
    var allFlights = [[String:Any]]()
    var allFlightPaths = [Path]()
    var closestFlight: Path?
    
    // MARK: - Initialization
    override func viewDidLoad() {
        initialStyle()

        // Set airplane mode indicator
        // statusIndicator.image = !SCNetworkReachabilityFlags.reachable ? #imageLiteral(resourceName: "Plane") : #imageLiteral(resourceName: "NoPlane")
    }
    
    // Reload flight whenever home appears
    override func viewDidAppear(_ animated: Bool) {
        loadFlights()
        setState()
    }

    func setState() {
        var state: AiRState = .NoFlights
        if allFlightPaths.count > 0 {
            closestFlight = allFlightPaths.sorted(by: { (p1, p2) -> Bool in
                return p1.date < p2.date
            }).first
            if isNow(flight: closestFlight!) { state = .FlightReady }
            else { state = .UpcomingFlight }
        }
        apply(state: state)
    }

    func isNow(flight: Path) -> Bool{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let now = dateFormatter.string(from: Date())
        let flightDate = flight.date
        if now == flightDate { return true }
        return false
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

    func loadFlights() {
        if let flightIDs = UserDefaults.standard.array(forKey: "flightPaths") as? [String] {
            for flightID in flightIDs {
                guard let data = Server.shared.getPersistedData(forID: flightID) else {
                    print("Error whilst trying to get persisted data")
                    continue
                }
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                    allFlights.append(json)
                    // Convert to all flight paths
                    allFlights.forEach({allFlightPaths.append(Path(source: $0))})
                } catch {
                    print("Error whilst parsing JSON from persisted flights")
                }
            }
        }
    }

    func apply(state: AiRState) {
        switch state {
        case .FlightReady:
            flightMgmtButtonsParentView.isHidden = true
            destinationLabel.text = "\(closestFlight!.destination)"
            dateLabel.text = "Ready to fly!"
            // Flight ready to experience!
            planeButton.isHidden = false
            planeButton.addShadow(intensity: .ChristianBale)
            experienceLabel.text = "Click the plane to experience AiR."
        case .UpcomingFlight:
            // Upcoming flight
            planeButton.isEnabled = false
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Make sure to enable airplane mode and have GPS turned on during your flight to experience AiR."
            destinationLabel.text = "\(closestFlight!.destination)"
            dateLabel.text = "\(closestFlight!.date)"
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
