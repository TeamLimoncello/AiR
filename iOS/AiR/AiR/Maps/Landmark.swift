//
//  Landmark.swift
//  AiR
//
//  Created by Jay Lees on 15/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import SceneKit

class Landmark {
    var id: Int
    var name: String
    var lat: Double
    var long: Double
    var position: SCNVector3
    var modelName: String?
    var description: String
    var height: String
    var established: String
    
    init(id: Int, name: String, lat: Double, long: Double, modelName: String?, description: String, height: String, established: String){
        self.id = id
        self.name = name
        self.lat = lat
        self.long = long
        self.modelName = modelName
        self.description = description
        self.height = height
        self.established = established
        self.position = SCNVector3(x: Float(latLongToWGS84(lat: lat, long: long).0 * scaleConstant), y: Float(latLongToWGS84(lat: lat, long: long).1 * scaleConstant), z: 0)
    }
    
}
