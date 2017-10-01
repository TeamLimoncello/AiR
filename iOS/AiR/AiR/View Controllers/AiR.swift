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
    let outerSphere = SCNSphere(radius: 500)
    var outerSphereNode: SCNNode!
    var flightPath: Path!
    var showSky = false

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        toggleSphereView.layer.cornerRadius = 8
        let scene = SCNScene()
        sceneView.scene = scene
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
        alterSphereGradient()
        outerSphere.firstMaterial?.isDoubleSided = true

        // Set the outer sphere node to the phones position (0, 0, 0)
        outerSphereNode = SCNNode(geometry: outerSphere)
        outerSphereNode.position = SCNVector3(0, 0, 0)

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
        landmarkInfoView.center = view.center
        landmarkInfoView.layer.cornerRadius = 16
        landmarkInfoView.addShadow(intensity: .Ehh)
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
                mapGrid?.landmarkNodes.forEach({ (scene) in
                    if result.node.parent == scene {
                        print("TRUEEEE")
                    }
                })
                
                if let nodeName = result.node.name {
                    print(nodeName)
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
        alterSphereGradient()
        showSky = !showSky
    }

    @IBAction func significantPlaceBackPressed(_ sender: Any) {
        significantPlaceInfoView.removeFromSuperview()
    }

    @IBAction func landmarkBackPressed(_ sender: Any) {
        landmarkInfoView.removeFromSuperview()
    }
    
    @IBAction func fakeParisButton(_ sender: Any) {
        displayLandmark(flightPath.landmarks.filter({$0.modelName == "EiffelTower"}).first!)
    }
    
    @IBAction func fakePisaButton(_ sender: Any) {
        displayLandmark(flightPath.landmarks.filter({$0.modelName == "Pisa"}).first!)
    }
    
    func alterSphereGradient() {
        let gradient = CAGradientLayer()
        let firstColour = showSky ? UIColor.orange.cgColor : UIColor.hexToRGB(hex: "29ABE2")!.cgColor
        let secondColour = showSky ? UIColor.hexToRGB(hex: "29ABE2")!.cgColor : UIColor.clear.cgColor
        gradient.colors = [firstColour, secondColour]
        let firstStop: NSNumber = showSky ? 0.1 : 0.2
        gradient.locations = [firstStop, 1] // GRADIENT STOP POSITIONS
        gradient.frame = sceneView.frame
        outerSphere.firstMaterial?.diffuse.contents = gradient
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
