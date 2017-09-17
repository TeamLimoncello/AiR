//
//  Waypoint.swift
//  AiR
//
//  Created by Jay Lees on 15/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

class Waypoint{
    var time: Int
    var lat: Double
    var long: Double
    var x: Double
    var y: Double
    var altitude: Int
    
    init(time: Int, lat: Double, long: Double, altitude: Int){
        self.time = time
        self.lat = lat
        self.long = long
        self.altitude = altitude
        let coords = latLongToWGS84(lat: lat, long: long)
        x = coords.0 * scaleConstant
        y = coords.1 * scaleConstant
    }
}
