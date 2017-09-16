//
//  MapGrid.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation

public class MapGrid {
    private let headingOfFlight: Float = 20.0
    
    private var mainPlane: SCNPlane
    public var mainPlaneNode: SCNNode
    private var lastKnownDeviceLocation: CLLocation?
    private var deviceLocationUpdateTime: Date?
    private var tiles: [MapTile]
    private var cities: [City]
    private var landmarks: [Landmark]
    
    init(deviceHeading: Float, path: Path){
        self.tiles = path.tiles
        self.cities = path.cities
        self.landmarks = path.landmarks
        mainPlane = SCNPlane(width: 10, height: 10)
        mainPlaneNode = SCNNode(geometry: mainPlane)
        mainPlaneNode.eulerAngles.x = degreesToRadians(90)
        mainPlaneNode.eulerAngles.y = degreesToRadians(deviceHeading + headingOfFlight)
        mainPlaneNode.position = SCNVector3(x: 0, y: -70, z: 0)
        
        addTiles()
        addCities()
        addLandmarks()
    }
    
    func addTiles() {
//        tiles.forEach({
//            mainPlaneNode.addChildNode($0.node)
//            $0.setPosition(SCNVector3($0.alat, 0, $0.along))
//        })

        
        let demoTile = SCNPlane(width: 1, height: 1)
        demoTile.firstMaterial?.diffuse.contents = UIColor.red
        let demoTileNode = SCNNode(geometry: demoTile)
        demoTileNode.position = SCNVector3(x: 0, y: 0, z: 0)
        mainPlaneNode.addChildNode(demoTileNode)
        
        
        
//        //Position the tiles in the correct position
//        //let numberOfColsPerRow = 1
//
//        //let numberOfRows = tiles.count / numberOfColsPerRow
//        //for rowNumber in 0...numberOfRows - 1 {
//            for columnNumber in 0...numberOfColsPerRow - 1 {
//                let tile = tiles[numberOfColsPerRow*rowNumber + columnNumber]
//                tile.setPosition(SCNVector3(columnNumber*Int(tile.resolution.w), 0, rowNumber*Int(tile.resolution.h)))
//            }
//        }
    }
    
    func addCities() {
        for city in cities {
            let cube = SCNBox(width: 10, height: 10, length: 10, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = UIColor.red
            let cubeNode = SCNNode(geometry: cube)
            let lat = city.lat - mainPlaneNode.position.x
            let long = city.long - mainPlaneNode.position.y
            cubeNode.position = SCNVector3(lat, 0, long)
            cubeNode.name = "city-\(city.id)"
            //mainPlaneNode.addChildNode(cubeNode)
        }
    }
    
    func addLandmarks(){
        //TODO: Fully implement
        
   
    }
    
//    func updateLocation(_ location: CLLocation){
//        self.lastKnownDeviceLocation = location
//        self.deviceLocationUpdateTime = Date()
//        let lat = location.coordinate.latitude
//        let long = location.coordinate.longitude
//
//        let tilesStartCoordinate = tiles[0].origin
//        let distanceBetweenLat = -lat.distance(to: tilesStartCoordinate.0)
//        let distanceBetweenLong = -long.distance(to: tilesStartCoordinate.1)
//
//        mainPlaneNode.position.x = Float(distanceBetweenLat)
//        mainPlaneNode.position.z = Float(distanceBetweenLong)
//
//        /*
//        print("Device is at: \(lat, long) and firstTileIsAt \(tiles[0].startCoordinate)" )
//        print("Distance:", distanceBetweenLat, distanceBetweenLong)
//        print(mainPlaneNode.position)
//         */
//    }
}
