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
        let meta = source["meta"] as! [String: Any]
        id = meta["id"] as! String
        start = meta["start"] as! String
        destination = meta["destination"] as! String
        time = meta["time"] as! String
        altitiude = meta["altitiude"] as! Double
        flightNo = meta["flightNo"] as! String
        tiles = [MapTile]()
        for tile in source["tiles"] as! [[String: Any]] {
            let alat = tile["alat"] as! Double
            let along = tile["along"] as! Double
            let blat = tile["blat"] as! Double
            let blong = tile["blong"] as! Double
            let imageURL = tile["image"] as! String
            var sigPlaces = [SignificantPlace]()
            for place in (tile["significantPlaces"] as! [[String: Any]]) {
                let lat = place["lat"] as! Double
                let long = place["long"] as! Double
                let name = place["name"] as! String
                sigPlaces.append(SignificantPlace(name: name, lat: lat, long: long))
            }

            let mapTile = MapTile(alat: alat, along: along, blat: blat, blong: blong, significantPlaces: sigPlaces)
            
            Server.shared.downloadImage(url: imageURL) { (image, error) in
                guard error == nil else {
                    print("Error whilst downloading image", error!)
                    return
                }
                mapTile.image = image
            }
            tiles.append(mapTile)
        }
    }
}
