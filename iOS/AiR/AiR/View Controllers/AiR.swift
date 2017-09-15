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
    @IBOutlet weak var toggleSphereView: UIView!
    @IBOutlet weak var toggleSphereButton: UIButton!
   
    @IBOutlet var significantPlaceInfoView: UIView!
    @IBOutlet weak var significantPlaceName: UILabel!
    @IBOutlet weak var significantPlaceEnglishName: UILabel!
    @IBOutlet weak var significantPlacePopulation: UILabel!
    
    var mapPlaneNode: SCNNode!
    var locationManager: CLLocationManager!
    var deviceHeading: CLLocationDirection?
    var mapGrid: MapGrid?
    var outerSphereNode: SCNNode!
    
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
        if AROrientationTrackingConfiguration.isSupported {
            let configuration = AROrientationTrackingConfiguration()
            sceneView.session.run(configuration)
            addOuterSphere()
            setupLocation()
            setupInfoView()
        } else {
            createDialogue(title: "Error", message: "Your device does not support this applicaition. Soz.", parentViewController: self)
        }
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
        let outerSphere = SCNSphere(radius: 500)
        outerSphere.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "skyGradient")
        outerSphere.firstMaterial?.isDoubleSided = true
        
        // Set the outer sphere node to the phones position (0, 0, 0)
        outerSphereNode = SCNNode(geometry: outerSphere)
        outerSphereNode.position = SCNVector3(0, 0, 0)
        outerSphereNode.isHidden = true
        
        // Add the node to our world
        sceneView.scene.rootNode.addChildNode(outerSphereNode)
    }
    
    fileprivate func addPlane(){
        // Load test JSON data from bundle
        if let json = Bundle.main.path(forResource: "pathEx", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: json), options: .alwaysMapped)
                let jsonObj = try? JSONSerialization.jsonObject(with: data, options: [])
                let path = Path(source: (jsonObj as? [String: Any])!)
                print(path.tiles)
                
                mapGrid = MapGrid(deviceHeading: Float(deviceHeading!.magnitude), tiles: path.tiles)
                sceneView.scene.rootNode.addChildNode(mapGrid!.mainPlaneNode)
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print("Failed to fetch local JSON resource")
        }
    }
    
    fileprivate func setupInfoView(){
        significantPlaceInfoView.layer.cornerRadius = 16
        significantPlaceInfoView.center = view.center
        significantPlaceInfoView.addShadow(intensity: .Ehh)
        view.addSubview(significantPlaceInfoView)
        significantPlaceInfoView.isHidden = true
    }
    
    func displaySignificantPlace(_ place: SignificantPlace){
        significantPlaceName.text = place.name
        significantPlaceEnglishName.text = "English Name: \(place.englishName)"
        if let population = place.population {
            significantPlacePopulation.text =  population
        }
        significantPlaceInfoView.isHidden = false
    }
    
    //MARK: - Action Methods
    @IBAction func toggleSpherePressed(_ sender: Any) {
        outerSphereNode.isHidden = !outerSphereNode.isHidden
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