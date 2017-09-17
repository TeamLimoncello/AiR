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
    @IBOutlet weak var nightModeView: UIView!
    @IBOutlet weak var backView: UIView!

    // Significant Place View
    @IBOutlet var significantPlaceInfoView: UIView!
    @IBOutlet weak var significantPlaceName: UILabel!
    @IBOutlet weak var significantPlaceEnglishName: UILabel!
    @IBOutlet weak var significantPlacePopulation: UILabel!

    // Landmark Info View
    @IBOutlet var landmarkInfoView: UIView!
    @IBOutlet weak var landmarkName: UILabel!
    @IBOutlet weak var landmarkHeight: UILabel!
    @IBOutlet weak var landmarkEstablished: UILabel!
    @IBOutlet weak var landmarkDescription: UILabel!

    var mapPlaneNode: SCNNode!
    var locationManager: CLLocationManager!
    var deviceHeading: CLLocationDirection?
    var mapGrid: MapGrid?
    var outerSphereNode: SCNNode!
    var flightPath: Path!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        toggleSphereView.layer.cornerRadius = 8
        //sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        //sceneView.autoenablesDefaultLighting = true
        //sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.isJitteringEnabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if AROrientationTrackingConfiguration.isSupported {
            let configuration = AROrientationTrackingConfiguration()
            sceneView.session.run(configuration)
            addOuterSphere()
            setupLocation()
            setupInfoView()
            styleButtons()
        } else {
            createDialogue(title: "Error", message: "Your device does not support Augmented Reality apps.", parentViewController: self, dismissOnCompletion: true)
        }
    }

    func styleButtons() {
        backView.addShadow(intensity: .Ehh)
        toggleSphereView.addShadow(intensity: .Ehh)
        nightModeView.addShadow(intensity: .Ehh)
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
        mapGrid = MapGrid(deviceHeading: Float(deviceHeading!.magnitude), path: flightPath)
        sceneView.scene.rootNode.addChildNode(mapGrid!.mainPlaneNode)

        self.mapGrid?.startFlight()
    }

    fileprivate func setupInfoView(){
        significantPlaceInfoView.layer.cornerRadius = 16
        significantPlaceInfoView.center = self.sceneView.center
        significantPlaceInfoView.addShadow(intensity: .Ehh)
    }

    func displayCity(_ place: City){
        significantPlaceName.text = place.name
        significantPlaceEnglishName.text = "English Name: \(place.englishName ?? place.name)"
        significantPlacePopulation.text =  "Population: \(place.population)"
        view.addSubview(significantPlaceInfoView)
    }

    func displayLandmark(_ landmark: Landmark){
        landmarkName.text = landmark.name
        landmarkHeight.text = "Height: \(landmark.height)"
        landmarkEstablished.text =  "Established: \(landmark.established)"
        landmarkDescription.text =  "\(landmark.description)"
        view.addSubview(landmarkInfoView)
    }

    //MARK: - Touch Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(location, options: nil)
            for result in hitTestResults {
                if let nodeName = result.node.name {
                    showInformation(nodeID: nodeName)
                }
            }
        }
    }

    //NodeIDs are given in the form {type}-{id}
    func showInformation(nodeID: String){
        let nodeID = nodeID.split(separator: "-")
        guard nodeID.count == 2 else { return }

        switch nodeID[0] {
        case "city":
            let cityID = Int(String(Array(nodeID[1])))
            displayCity((flightPath.cities.filter({$0.id == cityID}).first)!)
            break
        case "landmark":
            print(nodeID[1])
            let landmarkName = String(Array(nodeID[1]))
            displayLandmark((flightPath.landmarks.filter({$0.name == landmarkName}).first)!)
            break
        default:
            print("Error whilst parsing touch")
        }
        
    }

    //MARK: - Action Methods
    @IBAction func exitARPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func toggleNightModePressed(_ sender: Any) {
         mapGrid?.changeTileType()
    }

    @IBAction func toggleSpherePressed(_ sender: Any) {
        outerSphereNode.isHidden = !outerSphereNode.isHidden
        //toggleSphereButton.setBackgroundImage(outerSphereNode.isHidden ? #imageLiteral(resourceName: "Earth") : , for: .normal)
    }

    @IBAction func significantPlaceBackPressed(_ sender: Any) {
        significantPlaceInfoView.removeFromSuperview()
    }

    @IBAction func landmarkBackPressed(_ sender: Any) {
        landmarkInfoView.removeFromSuperview()
    }
}

extension AiR: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        deviceHeading = newHeading.trueHeading
        manager.stopUpdatingHeading()
        addPlane()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let grid = mapGrid {
//            //grid.updateLocation(locations[0])
//        }
    }
}
