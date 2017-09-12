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

class ViewController: UIViewController {

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
        let tile1 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "skyGradient")!)
        let tile2 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let tile3 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "skyGradient")!)
        let tile4 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let tile5 = MapTile(startCoordinate: (0, 0), image:  UIImage(named: "skyGradient")!)
        let tile6 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let tile7 = MapTile(startCoordinate: (0, 0), image:  UIImage(named: "skyGradient")!)
        let tile8 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let tile9 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "skyGradient")!)
        let tile10 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let tile11 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "skyGradient")!)
        let tile12 = MapTile(startCoordinate: (0, 0), image: UIImage(named: "testGradient")!)
        let allTiles = [tile1, tile2, tile3, tile4, tile5, tile6, tile7, tile8, tile9, tile10, tile11, tile12]
        
        let mapGrid = MapGrid(deviceHeading: Float(deviceHeading!.magnitude), tiles: allTiles)
        sceneView.scene.rootNode.addChildNode(mapGrid.mainPlaneNode)
    
    }
    
    fileprivate func getLocation(){

        
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        deviceHeading = newHeading.trueHeading
        manager.stopUpdatingHeading()
        addPlane()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
    }
}
