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
    let tiles: [MapTile]!
    /// Accepts a JSON source to construct the path
    init(source: [[String: Any]]) {
        tiles = []
        for tile in source {
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
