//
//  ViewFlightsViewController.swift
//  AiR
//
//  Created by Brendon Warwick on 13/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

class ViewFlights: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var flightsCard: UIView!
    @IBOutlet weak var flightsTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        styleView()
        loadFlights()
        flightsTableView.delegate = self
        flightsTableView.dataSource = self
    }
    
    func styleView() {
        flightsCard.layer.cornerRadius = 16
        flightsCard.addShadow(intensity: .Weak)
        flightsTableView.layer.cornerRadius = 8
    }
    
    func loadFlights() {
        // UserDefaults.standard.array(forKey: "flightPaths")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7 // number of flights
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "flightCell", for: indexPath) as UITableViewCell
        let cellView = cell.viewWithTag(1)
        cellView?.backgroundColor = .blue
        let cellDestination = cell.viewWithTag(2) as? UILabel
        cellDestination?.text = "SFO to NYC"
        let cellDestTime = cell.viewWithTag(3) as? UILabel
        cellDestTime?.text = "21st July"
        return cell
    }
    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
