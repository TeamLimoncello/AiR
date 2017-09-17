//
//  Billboard.swift
//  AiR
//
//  Created by Brendon Warwick on 16/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import SceneKit
import UIKit

public class Billboard {
    
    var node: SCNNode
    
    init(withName name : String, englishName: String?, position: SCNVector3) {
        // The board
        let board = SCNBox(width: 1.0, height: 1/3, length: 1/3, chamferRadius: 0.1)
        let text = englishName == nil ? name : englishName
        self.node = SCNNode(geometry: board)
        self.node.position = SCNVector3(position.x, position.y+1, position.z)
        self.node.name = "city-\(text!)"
        
    
        if let image = imageWithText(text: text!, imageSize: CGSize(width:100, height: 100/3), backgroundColor: UIColor.hexToRGB(hex: "195083")!) {
            board.firstMaterial?.diffuse.contents = image
        }
        
        // The pole
        let pole = SCNTube(innerRadius: 0.1, outerRadius: 0.1, height: 1.2)
        pole.firstMaterial?.diffuse.contents  = UIColor.black
        pole.firstMaterial?.specular.contents = UIColor.white
        let poleNode = SCNNode(geometry: pole)
        poleNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        self.node.addChildNode(poleNode)
        self.node.eulerAngles.x = Float(degreesToRadians(90))
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Create an image from some text
    fileprivate func imageWithText(text: String, fontSize: CGFloat = 10, fontColor: UIColor = .white, imageSize: CGSize, backgroundColor: UIColor) -> UIImage? {
        let imageRect = CGRect(origin: CGPoint.zero, size: imageSize)
        UIGraphicsBeginImageContext(imageSize)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        // Fill the background with a color
        context.setFillColor(backgroundColor.cgColor)
        context.fill(imageRect)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        // Define the attributes of the text
        let attributes = [
            NSAttributedStringKey.font: UIFont(name: "Montserrat", size:fontSize),
            NSAttributedStringKey.paragraphStyle: paragraphStyle,
            NSAttributedStringKey.foregroundColor: fontColor
        ]
        // Determine the width/height of the text for the attributes
        let textSize = text.size(withAttributes: (attributes as Any as! [NSAttributedStringKey : Any]))
        // Draw text in the current context
        text.draw(at: CGPoint(x: imageSize.width/2 - textSize.width/2, y: imageSize.height/2 - textSize.height/2), withAttributes: (attributes as Any as! [NSAttributedStringKey : Any]))
        if let image = UIGraphicsGetImageFromCurrentImageContext() { return image }
        return nil
    }
}

