//
//  ViewController.swift
//  AiR
//
//  Created by Jay Lees on 11/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    var mapPlaneNode: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = AROrientationTrackingConfiguration()
        sceneView.session.run(configuration)
        addOuterSphere()
        addPlane()
    }
    
    fileprivate func addOuterSphere() {
        // Create a double sided sphere of radius 1m
        let outerSphere = SCNSphere(radius: 2.5)
        outerSphere.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "testGradient")
        outerSphere.firstMaterial?.isDoubleSided = true
        
        // Set the outer sphere node to the phones position (0, 0, 0)
        let outerSphereNode = SCNNode(geometry: outerSphere)
        outerSphereNode.position = SCNVector3(0, 0, 0)
        
        // Add the node to our world
        sceneView.scene.rootNode.addChildNode(outerSphereNode)
    }
    
    fileprivate func addPlane(){
        let plane = SCNPlane(width: 100, height: 5)
        plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "testMap")
        plane.firstMaterial?.isDoubleSided = true
        mapPlaneNode = SCNNode(geometry: plane)
        mapPlaneNode.position = SCNVector3(-50, -1.4, 0)
        mapPlaneNode.rotation = SCNVector4(1, 0, 0, degreesToRadians(90))
        
        sceneView.scene.rootNode.addChildNode(mapPlaneNode)
        
        animateMapMoving()
    }
    
    func animateMapMoving(){
        UIView.animate(withDuration: 10) {
            
            //NB: SCNVector IS NOT ANIMATABLE!!!!!!!!!!!!!!!!
            //TODO: Make the thing move
            self.mapPlaneNode.position = SCNVector3(x: 50, y: -1.4, z: 0)
        }
    }
    
    



}

