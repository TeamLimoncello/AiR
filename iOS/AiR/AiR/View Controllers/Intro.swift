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
    @IBOutlet weak var airLogoView: UIView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var planeButton: UIButton!
    @IBOutlet weak var planeHorizontalConstraint: NSLayoutConstraint!
    @IBOutlet weak var planeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var experienceLabel: UILabel!
    @IBOutlet weak var flightMgmtButtonsParentView: UIView!
    @IBOutlet weak var flightPanelParentView: UIView!
    @IBOutlet weak var createFlightView: UIView!
    @IBOutlet weak var createFlightButton: UIButton!
    @IBOutlet weak var createFlightButtonWidth: NSLayoutConstraint!
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
    }

    // Reload flight whenever home appears
    override func viewDidAppear(_ animated: Bool) {
        loadFlights()
        setState()
    }

    func initialStyle() {
        // Style Flight Management buttons
        flightMgmtButtonsParentView.backgroundColor = .clear
        createFlightView.layer.cornerRadius = 8
        createFlightView.addShadow(intensity: .Weak)
        viewFlightsView.layer.cornerRadius = 8
        viewFlightsView.addShadow(intensity: .Weak)
        flightPanelParentView.layer.cornerRadius = 24
        flightPanelParentView.addShadow(intensity: .Ehh)
    }

    override func viewDidLayoutSubviews() {
        if firstLoad {
            airLogoView.layer.cornerRadius = airLogoView.frame.size.width
            firstLoad = false
        }
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
        print("Applying \(state)")
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
    
    func loadFlights() {
        var allFlights = [[String:Any]]()
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
            destinationLabel.isHidden = false
            destinationLabel.text = "\(closestFlight?.destination ?? "San Francisco")"
            dateLabel.isHidden = false
            dateLabel.text = "Ready to fly!"
            // Flight ready to experience!
            planeButton.isHidden = false
            planeButton.isEnabled = true
            planeButton.addShadow(intensity: .ChristianBale)
            flightPanelParentView.isHidden = false
            experienceLabel.text = "Click the plane to experience AiR."
        case .UpcomingFlight:
            // Upcoming flight
            planeButton.isHidden = false
            planeButton.isEnabled = false
            dateLabel.isHidden = false
            viewFlightsView.isHidden = false
            destinationLabel.isHidden = false
            flightPanelParentView.isHidden = false
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Make sure to come back when you've taken off to experience AiR."
            destinationLabel.text = "\(closestFlight?.destination ?? "San Francisco")"
            dateLabel.text = "\(closestFlight?.date ?? "21st July")"
            createFlightButtonWidth.constant = 140
            self.view.layoutIfNeeded()
        default:
            // No flights setup
            planeButton.isHidden = true
            flightMgmtButtonsParentView.isHidden = false
            experienceLabel.text = "Add a flight to begin the AiR experience."
            destinationLabel.isHidden = true
            dateLabel.isHidden = true
            viewFlightsView.isHidden = true
            flightPanelParentView.isHidden = true
            createFlightButtonWidth.constant = flightMgmtButtonsParentView.frame.width
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func planePressed(_ sender: Any) {
        self.planeHorizontalConstraint.constant += 520
        self.planeTopConstraint.constant -= 128
        self.planeButton.titleLabel?.font = UIFont(name: (self.planeButton.titleLabel?.font.fontName)!, size: 200)
        UIView.animate(withDuration: 1.1, animations: {
            self.view.layoutIfNeeded()
            self.dateLabel.text = "Have Fun!"
            self.experienceLabel.isHidden = true
        }, completion: { s in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "AiR") as! AiR
            controller.flightPath = self.closestFlight
            self.present(controller, animated: true, completion: nil)
        })
    }
}
