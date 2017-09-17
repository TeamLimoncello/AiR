//
//  SignificantPlace.swift
//  AiR
//
//  Created by Brendon Warwick on 14/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import SceneKit

/// A significant city that is contained within a MapTile
class City {
    var id: Int
    var name: String
    var lat: Double
    var long: Double
    var englishName: String?
    var population: Int
    var position: SCNVector3
    
    init(id: Int, name: String, englishName: String?, lat: Double, long: Double, population: Int){
        self.id = id
        self.name = name
        self.englishName = englishName
        self.lat = lat
        self.long = long
        self.position = SCNVector3(x: Float(latLongToWGS84(lat: lat, long: long).0 * scaleConstant), y: Float(latLongToWGS84(lat: lat, long: long).1 * scaleConstant), z: 0.3)
        self.population = population
    }
    
}
