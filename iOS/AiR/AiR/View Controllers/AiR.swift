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

class AiR: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    var mapPlaneNode: SCNNode!
    var locationManager: CLLocationManager!
    var deviceHeading: CLLocationDirection?
    var mapGrid: MapGrid?
    @IBOutlet weak var toggleSphereView: UIView!
    @IBOutlet weak var toggleSphereButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toggleSphereView.layer.cornerRadius = 8
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        //sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = AROrientationTrackingConfiguration()
        sceneView.session.run(configuration)
        addOuterSphere()
        setupLocation()
        getLocation()
    }
    
    fileprivate func setupLocation(){
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
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
        var allTiles = [MapTile]()
        
        
        for i in 0...100 {
            for j in 0...5 {
                let tile = MapTile(startCoordinate: (Double(i), Double(j)), color: UIColor.white)
                allTiles.append(tile)
            }
        }
        
        mapGrid = MapGrid(deviceHeading: Float(deviceHeading!.magnitude), tiles: allTiles)
        sceneView.scene.rootNode.addChildNode(mapGrid!.mainPlaneNode)
    
    }
    
    fileprivate func getLocation(){

        
    }
    
    @IBAction func toggleSpherePressed(_ sender: Any) {
    
    }
}

extension AiR: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        deviceHeading = newHeading.trueHeading
        manager.stopUpdatingHeading()
        addPlane()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let grid = mapGrid {
            grid.updateLocation(locations[0])
        }
    }
}
