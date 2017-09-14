//
//  MapTile.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import ARKit

public class MapTile {
    private var plane: SCNPlane
    public var startCoordinate: (Double, Double)
    public var node: SCNNode
    public let size = 100
    
    init(startCoordinate: (Double, Double), overlay: Any){
        self.startCoordinate = startCoordinate
        self.plane = SCNPlane(width: CGFloat(size), height: CGFloat(size))
        self.plane.firstMaterial?.diffuse.contents = overlay
        self.plane.firstMaterial?.isDoubleSided = true
        self.node = SCNNode(geometry: plane)
    }
    
    public func setPosition(_ vector: SCNVector3){
        node.position = vector
    }
}
