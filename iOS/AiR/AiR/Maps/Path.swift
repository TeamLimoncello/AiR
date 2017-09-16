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

    let origin: String
    let originCode: String
    let destination: String
    let destinationCode: String
    let date: String
    let flightCode: String
    let tiles: [MapTile]!
    let waypoints: [Waypoint]!
    let cities: [City]!
    let landmarks: [Landmark]!


    /// Accepts a JSON source to construct the path

    init(source: [String: Any]) {

        //Metadata parsing
        let meta = source["meta"] as! [String: Any]
        origin = meta["origin"] as! String
        originCode = meta["originCode"] as! String
        destination = meta["destination"] as! String
        destinationCode = meta["destinationCode"] as! String
        date = meta["date"] as! String
        flightCode = meta["flightCode"] as! String


        //Waypoint parsing
        let pathString = source["path"] as! String
        let pathSubstrings = pathString.split(separator: "\n")
        waypoints = pathSubstrings.map { (substring) -> Waypoint in
            let commaSeparated = substring.split(separator: ",")
            return Waypoint(time: Int(commaSeparated[0])!, lat: Double(commaSeparated[1])!, long: Double(commaSeparated[2])!, altitude: Int(commaSeparated[3])!)
        }

        //Tiles parsing
        tiles = [MapTile]()
        for tile in source["tiles"] as! [[String: Any]] {
            let alat = tile["alat"] as! Double
            let along = tile["along"] as! Double
            let blat = tile["blat"] as! Double
            let blong = tile["blong"] as! Double
            let imageURL = tile["image"] as! String
            let mapTile = MapTile(alat: alat, along: along, blat: blat, blong: blong)
            Server.shared.DownloadImage(url: imageURL) { (image, error) in
                guard error == nil else {
                    print("Error whilst downloading image", error!)
                    return
                }
                mapTile.image = image
            }
            tiles.append(mapTile)
        }

        //Cities parsing
        //We use the cities counter to identify the ID of the node when it is tapped
        var citiesID = 0
        cities = [City]()
        for place in (source["cities"] as! [[String: Any]]) {
            let lat = place["lat"] as! Float
            let long = place["long"] as! Float
            let name = place["name"] as! String
            let englishName = place["name_en"] as? String
            let population = place["population"] as! Int
            cities.append(City(id: citiesID, name: name, englishName: englishName, lat: lat, long: long, population: population))
            citiesID += 1
        }

        //Landmarks parsing
        var landmarkID = 0
        landmarks = [Landmark]()
        for landmark in source["landmarks"] as! [[String:Any]]{
            let lat = landmark["lat"] as! Float
            let long = landmark["long"] as! Float
            let name = landmark["name"] as! String
            let modelName = landmark["model_name"] as? String
            landmarks.append(Landmark(id: landmarkID, name: name, lat: lat, long: long, modelName: modelName))
            landmarkID += 1
        }
        
        
        //Debug statements
//        print("Adding landmarks \(landmarks.map({$0.name}))")
//        print("Adding cities \(cities.map({$0.name}))")
//        print("Adding tiles \(tiles.map({$0.origin}))")
    }
}
