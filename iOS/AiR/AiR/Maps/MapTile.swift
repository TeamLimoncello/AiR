//
//  MapTile.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import ARKit

/// A single tile on the path for the flight
public class MapTile {
    private var plane: SCNPlane
    public var node: SCNNode
    let alat: Double
    let along: Double
    let blat: Double
    let blong: Double
    let origin: (lat: Double, long: Double)
    let resolution: (w: Double, h: Double)
    let image: String
    let significantPlaces: [SignificantPlace]
    let scaleConstant: Double = 1000000.0
    
    init(alat: Double, along: Double, blat: Double, blong: Double, image: String, significantPlaces: [SignificantPlace]){
        self.image = image
        self.alat = alat
        self.blat = blat
        self.along = along
        self.blong = blong
        self.origin = (alat, along)
        self.resolution = ((blat-alat)*scaleConstant, (blong-along)*scaleConstant)
        self.significantPlaces = significantPlaces
        self.plane = SCNPlane(width: CGFloat(self.resolution.w), height: CGFloat(self.resolution.h))
        self.plane.firstMaterial?.diffuse.contents = image
        self.plane.firstMaterial?.isDoubleSided = true
        self.node = SCNNode(geometry: plane)
    }
    
    public func setPosition(_ vector: SCNVector3){
        node.position = vector
    }
}
