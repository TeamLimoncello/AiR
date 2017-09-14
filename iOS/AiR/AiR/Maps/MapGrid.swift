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
    private var deviceLocation: CLLocation?
    private var tiles: [MapTile]
    
    init(deviceHeading: Float, tiles: [MapTile]){
        self.tiles = tiles
        mainPlane = SCNPlane(width: 10, height: 10)
        mainPlaneNode = SCNNode(geometry: mainPlane)
        mainPlaneNode.eulerAngles.x = degreesToRadians(90)
        mainPlaneNode.eulerAngles.y = degreesToRadians(deviceHeading + headingOfFlight)
        mainPlaneNode.position = SCNVector3(x: 0, y: -70, z: 0)
        
        tiles.forEach({mainPlaneNode.addChildNode($0.node)})
        
        //Position the tiles in the correct position
        let numberOfColsPerRow = 6
        
        let numberOfRows = tiles.count / numberOfColsPerRow
        for rowNumber in 0...numberOfRows - 1 {
            for columnNumber in 0...numberOfColsPerRow - 1 {
                let tile = tiles[numberOfColsPerRow*rowNumber + columnNumber]
                tile.setPosition(SCNVector3(columnNumber*tile.size, rowNumber*tile.size, 0))
            }
        }
    }
    
    func updateLocation(_ location: CLLocation){
        self.deviceLocation = location
        let lat = location.coordinate.latitude
        let long = location.coordinate.longitude
        
        let tilesStartCoordinate = tiles[0].startCoordinate
        let distanceBetweenLat = -lat.distance(to: tilesStartCoordinate.0)
        let distanceBetweenLong = -long.distance(to: tilesStartCoordinate.1)
        
        mainPlaneNode.position.x = Float(distanceBetweenLat)
        mainPlaneNode.position.z = Float(distanceBetweenLong)
        
        /*
        print("Device is at: \(lat, long) and firstTileIsAt \(tiles[0].startCoordinate)" )
        print("Distance:", distanceBetweenLat, distanceBetweenLong)
        print(mainPlaneNode.position)
         */
    }

    
}
