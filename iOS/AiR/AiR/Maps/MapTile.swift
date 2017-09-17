//
//  MapTile.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit
import ARKit

enum TileType {
    case Day
    case Night
}


/// A single tile on the path for the flight
public class MapTile {
    private var plane: SCNPlane
    public var node: SCNNode
    public var geoCoordinate: (alat: Double, along: Double, blat: Double, blong: Double)
    var origin: (x: Double, y: Double)
    var size: (w: Double, h: Double)
    var image: UIImage?
    var tileType: TileType
    
    init(alat: Double, along: Double, blat: Double, blong: Double, type: TileType){
        self.geoCoordinate = (alat, along, blat, blong)
        let originWGS84 = latLongToWGS84(lat: alat, long: along)
        self.origin = (x: originWGS84.0 * scaleConstant, y: -originWGS84.1 * scaleConstant)
        
        let width = (latLongToWGS84(lat: blat, long: blong).0 - latLongToWGS84(lat: alat, long: along).0) * scaleConstant
        let height = (latLongToWGS84(lat: blat, long: blong).1 - latLongToWGS84(lat: alat, long: along).1) * scaleConstant
        self.size = (w: width, h: height)
        
        self.plane = SCNPlane(width: CGFloat(self.size.w), height: CGFloat(self.size.h))
        
        self.node = SCNNode(geometry: plane)
        self.node.name = "tile-\(alat)-\(along)"
        
        self.tileType = type
    }
    
    public func setPosition(_ vector: SCNVector3){
        node.position = vector
    }
    
    public func setImage(_ image: UIImage){
        self.image = image
        
        if tileType == .Night {
            let context = CIContext(options: nil)
            
            if let currentFilter = CIFilter(name: "CIFalseColor") {
                let beginImage = CIImage(image: image)
                currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
                
                let yellowUI = UIColor(red: 222/255.0, green: 199/255.0, blue: 136/255.0, alpha: 1.0)
                let blackUI = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
                let yellow = CIColor(color: yellowUI)
                let black = CIColor(color: blackUI)
                
                currentFilter.setValue(black, forKey: "inputColor0")
                currentFilter.setValue(yellow, forKey: "inputColor1")
                
                if let output = currentFilter.outputImage {
                    if let cgimg = context.createCGImage(output, from: output.extent) {
                        let processedImage = UIImage(cgImage: cgimg)
                       self.plane.firstMaterial?.diffuse.contents = processedImage
                    }
                }
            }
        } else {
            self.plane.firstMaterial?.diffuse.contents = image
        }
        self.plane.firstMaterial?.isDoubleSided = true
    }
}
