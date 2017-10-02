//: Playground - noun: a place where people can play

import SceneKit
import UIKit
import PlaygroundSupport

// Create a scene view with an empty scene
var sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
var scene = SCNScene()
sceneView.scene = scene

// Start a live preview of that view
PlaygroundPage.current.liveView = sceneView

// Default lighting
sceneView.autoenablesDefaultLighting = true

// A camera
var cameraNode = SCNNode()
cameraNode.camera = SCNCamera()
cameraNode.position = SCNVector3(x: 0, y: 0, z: 4)
scene.rootNode.addChildNode(cameraNode)

// A geometry object
var dick = SCNTube(innerRadius: 0.1, outerRadius: 0.1, height: 1.2)
// configure the geometry object
dick.firstMaterial?.diffuse.contents  = UIColor.black
dick.firstMaterial?.specular.contents = UIColor.gray
var dickNode = SCNNode(geometry: dick)
dickNode.position = SCNVector3(0, 0, 0)
scene.rootNode.addChildNode(dickNode)

var billboard = SCNBox(width: 3, height: 1, length: 1, chamferRadius: 0.2)
// configure the geometry object
if let image = imageWithText(text: "San Francisco", imageSize: CGSize(width:300, height: 100), backgroundColor: hexToRGB(hex: "#195083")!) {
    billboard.firstMaterial?.diffuse.contents = image
}
// billboard.firstMaterial?.specular.contents = UIColor.white
var billboardNode = SCNNode(geometry: billboard)
billboardNode.position = SCNVector3(0, 1, 0)
scene.rootNode.addChildNode(billboardNode)

// Utilities

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
        NSAttributedStringKey.font: UIFont(name: "Arial", size:fontSize),
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

func hexToRGB(hex: String) -> UIColor? {
    var array = hex.characters.map {String($0)}
    if array.first! == "#" { array = Array(array.dropFirst()) }
    if array.count == 6 {
        if let red = UInt8("\(array[0])\(array[1])", radix: 16), let green = UInt8("\(array[2])\(array[3])", radix: 16), let blue = UInt8("\(array[4])\(array[5])", radix: 16) {
            return UIColor(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
        }
    }
    return nil
}
