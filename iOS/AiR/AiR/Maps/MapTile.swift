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
    private var startCoordinate: (Double, Double)
    public var node: SCNNode
    
    init(startCoordinate: (Double, Double), image: UIImage){
        self.startCoordinate = startCoordinate
        self.plane = SCNPlane(width: 1, height: 1)
        self.plane.firstMaterial?.diffuse.contents = image
        self.plane.firstMaterial?.isDoubleSided = true
        self.node = SCNNode(geometry: plane)
    }
    
    public func setPosition(_ vector: SCNVector3){
        node.position = vector
    }
}
