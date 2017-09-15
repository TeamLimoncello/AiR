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
    var englishName: String
    var population: String?
    
    init(name: String, englishName: String, lat: Double, long: Double, population: String?){
        self.name = name
        self.englishName = englishName
        self.lat = lat
        self.long = long
        self.population = population
    }
    
}
