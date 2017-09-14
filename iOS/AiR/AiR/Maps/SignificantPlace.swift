//
//  SignificantPlace.swift
//  AiR
//
//  Created by Brendon Warwick on 14/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

/// A significant place that is contained within a MapTile
class SignificantPlace {
    var name: String
    var lat: Double
    var long: Double
    
    init(name: String, lat: Double, long: Double){
        self.name = name
        self.lat = lat
        self.long = long
    }
}
