//
//  Landmark.swift
//  AiR
//
//  Created by Jay Lees on 15/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

class Landmark {
    var id: Int
    var name: String
    var lat: Float
    var long: Float
    var modelName: String?
    
    init(id: Int, name: String, lat: Float, long: Float, modelName: String?){
        self.id = id
        self.name = name
        self.lat = lat
        self.long = long
        self.modelName = modelName
    }
    
}
