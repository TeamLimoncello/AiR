//
//  MapGrid.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import ARKit


class MapGrid {
    var mainPlane: SCNPlane
    var mainPlaneNode: SCNNode
    init(deviceHeading: Float, tiles: [MapTile]){
        let angleOfFlight: Float = 20.0
        
        mainPlane = SCNPlane(width: 10, height: 10)
        mainPlaneNode = SCNNode(geometry: mainPlane)
        mainPlaneNode.eulerAngles.x = degreesToRadians(90)
        mainPlaneNode.eulerAngles.y = degreesToRadians(deviceHeading + angleOfFlight)
        mainPlaneNode.position = SCNVector3(x: 0, y: -10, z: 0)
        
        tiles.forEach({mainPlaneNode.addChildNode($0.node)})
        
        //Position the tiles in the correct position
        let numberOfColsPerRow = 6
        
        let numberOfRows = tiles.count / numberOfColsPerRow
        for rowNumber in 0...numberOfRows - 1 {
            for columnNumber in 0...numberOfColsPerRow - 1 {
                tiles[numberOfColsPerRow*rowNumber + columnNumber].setPosition(SCNVector3(columnNumber, rowNumber, 0))
            }
        }
    }
}
