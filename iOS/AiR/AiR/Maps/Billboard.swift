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

class Billboard {
    
    func create(with text: String?, position: SCNVector3) -> SCNNode {
        // The pole
        let pole = SCNTube(innerRadius: 0.1, outerRadius: 0.1, height: 1.2)
        pole.firstMaterial?.diffuse.contents  = UIColor.black
        pole.firstMaterial?.specular.contents = UIColor.white
        let poleNode = SCNNode(geometry: pole)
        poleNode.position = position
        // The board
        let board = SCNBox(width: 3, height: 1, length: 1, chamferRadius: 0.2)
        if let image = imageWithText(text: text!, imageSize: CGSize(width:300, height: 100), backgroundColor: UIColor.hexToRGB(hex: "#195083")!) {
            board.firstMaterial?.diffuse.contents = image
        }
        let boardNode = SCNNode(geometry: board)
        boardNode.position = SCNVector3(position.x, position.y+1, position.z)
        // The billboard
        let billboardNode = SCNNode()
        billboardNode.addChildNode(poleNode)
        billboardNode.addChildNode(boardNode)
        return billboardNode
    }
    
    /// Create an image from some text
    func imageWithText(text: String, fontSize: CGFloat = 30, fontColor: UIColor = .white, imageSize: CGSize, backgroundColor: UIColor) -> UIImage? {
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

