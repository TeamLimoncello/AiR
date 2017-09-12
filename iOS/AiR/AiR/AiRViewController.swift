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
import CoreLocation

class AiRViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    var mapPlaneNode: SCNNode!
    var locationManager: CLLocationManager!
    var deviceHeading: CLLocationDirection?
    
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
        setupLocation()
    }
    
    fileprivate func setupLocation(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
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
        //sceneView.scene.rootNode.addChildNode(outerSphereNode)
    }
    
    fileprivate func addPlane(){
        let plane = SCNPlane(width: 100, height: 20)
        plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "testGradient")
        plane.firstMaterial?.isDoubleSided = true
        mapPlaneNode = SCNNode(geometry: plane)
        
        let angleOfFlight: Double = 50.0
        
        mapPlaneNode.eulerAngles.x = degreesToRadians(90)
        mapPlaneNode.eulerAngles.y = degreesToRadians(Float(deviceHeading!.magnitude + angleOfFlight))
        
        //Move to the starting position
        mapPlaneNode.position = SCNVector3(0, -10, 0)
        
        sceneView.scene.rootNode.addChildNode(mapPlaneNode)
        print("Starting at angle: \(mapPlaneNode.eulerAngles.y)")
        
        animateMapMoving()
    }
    
    func animateMapMoving(){
        let action = SCNAction.move(to: SCNVector3(50, -1.4, 0), duration: 100)
        //mapPlaneNode.runAction(action)
    }
}

extension AiRViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        deviceHeading = newHeading.trueHeading
        print("Device heading is: \(deviceHeading), mag is: \(deviceHeading!.magnitude) and rads is \(degreesToRadians(Float(deviceHeading!.magnitude)))")
        manager.stopUpdatingHeading()
        addPlane()
    }
}

