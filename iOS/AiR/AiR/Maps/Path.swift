//
//  Path.swift
//  AiR
//
//  Created by Brendon Warwick on 14/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation

/// The Path, composed of MapTiles, for a given flight
class Path {
    let id: String!
    let start: String!
    let destination: String!
    let time: String!
    let altitiude: Double!
    let flightNo: String!
    let tiles: [MapTile]!
    
    /// Accepts a JSON source to construct the path
    init(source: [String: Any]) {
        id = source["id"] as! String
        start = source["start"] as! String
        destination = source["destination"] as! String
        time = source["time"] as! String
        altitiude = source["altitiude"] as! Double
        flightNo = source["flightNo"] as! String
        tiles = [MapTile]()
        for tile in source["tiles"] as! [[String: Any]] {
            let alat = tile["alat"] as! Double
            let along = tile["along"] as! Double
            let blat = tile["blat"] as! Double
            let blong = tile["blong"] as! Double
            let image = tile["image"] as! String
            var sigPlaces = [SignificantPlace]()
            for place in (tile["significantPlaces"] as! [[String: Any]]) {
                let lat = place["lat"] as! Double
                let long = place["long"] as! Double
                let name = place["name"] as! String
                sigPlaces.append(SignificantPlace(name: name, lat: lat, long: long))
            }
            tiles.append(MapTile(alat: alat, along: along, blat: blat, blong: blong, image: image, significantPlaces: sigPlaces))
        }
    }
}
