//
//  SignificantPlace.swift
//  AiR
//
//  Created by Brendon Warwick on 14/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

/// A significant city that is contained within a MapTile
class City {
    var id: Int
    var name: String
    var lat: Float
    var long: Float
    var englishName: String?
    var population: Int
    
    init(id: Int, name: String, englishName: String?, lat: Float, long: Float, population: Int){
        self.id = id
        self.name = name
        self.englishName = englishName
        self.lat = lat
        self.long = long
        self.population = population
    }
    
}
