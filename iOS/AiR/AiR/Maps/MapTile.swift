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
    
    init(alat: Double, along: Double, blat: Double, blong: Double, image: String, significantPlaces: [SignificantPlace]){
        self.image = image
        //self.plane = SCNPlane(width: CGFloat(size), height: CGFloat(size))
        self.plane = SCNPlane(width: 100.0, height: 100.0)
        self.plane.firstMaterial?.diffuse.contents = image
        self.plane.firstMaterial?.isDoubleSided = true
        self.node = SCNNode(geometry: plane)
        self.alat = alat
        self.blat = blat
        self.along = along
        self.blong = blong
        self.origin = (alat, along)
        self.resolution = (blat-alat, blong-along)
        self.significantPlaces = significantPlaces
    }
    
    public func setPosition(_ vector: SCNVector3){
        node.position = vector
    }
}
