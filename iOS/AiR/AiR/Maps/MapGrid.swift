//
//  MapGrid.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation

public class MapGrid {
    private let headingOfFlight: Float = 20.0
    
    private var mainPlane: SCNPlane
    public var mainPlaneNode: SCNNode
    private var lastKnownDeviceLocation: CLLocation?
    private var deviceLocationUpdateTime: Date?
    private var tiles: [MapTile]
    private var cities: [City]
    private var landmarks: [Landmark]
    private var waypoints: [Waypoint]
    private var offsetPosition: Waypoint?
    private var currentType: TileType = .Day
    private var altitudeOffset: Double
    private var locationTimer: Timer?
    
    init(deviceHeading: Float, path: Path){
        self.tiles = path.tiles
        self.cities = path.cities
        self.landmarks = path.landmarks
        self.waypoints = path.waypoints
        self.altitudeOffset = 0
        mainPlane = SCNPlane(width: 10, height: 10)
        mainPlane.firstMaterial?.diffuse.contents = UIColor.clear
        mainPlaneNode = SCNNode(geometry: mainPlane)
        //Rotates into the correct plane
        mainPlaneNode.eulerAngles.x = Float(degreesToRadians(-90))
        //mainPlaneNode.eulerAngles.y = degreesToRadians(deviceHeading + headingOfFlight)
        
        //Moves the device 70 meters into the air
        mainPlaneNode.position = SCNVector3(x: 0, y: -1, z: 0)
        
        addTiles(type: currentType)
        addCities()
        addLandmarks()
    }
    
    public func changeTileType(){
        currentType = currentType == .Day ? .Night : .Day
        addTiles(type: currentType)
    }
    
    /*
     Notes:
         X-Axis is right(+) and left(-)
         Y-Axis is backwards(-) and forwards(+)
         Z-Axis is closer to camera(+) and further away(-)
 
     */
    private func addTiles(type: TileType) {
        mainPlaneNode.childNodes.filter({($0.name?.contains("tile"))!}).forEach({$0.removeFromParentNode()})
        tiles.filter({$0.tileType == type}).forEach({
            let x = $0.origin.x + ($0.size.w/2)
            let y = -$0.origin.y + ($0.size.h/2)
            
            $0.setPosition(SCNVector3(x: Float(x), y: Float(y), z: 0))
            
            mainPlaneNode.addChildNode($0.node)
        })
     
        //If we have not alreayd set an offset, set it now and move the plane there
        //Position the plane node as the negative of where the map elements are
        if offsetPosition == nil {
            offsetPosition = waypoints.first
            self.mainPlaneNode.position = SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08 + altitudeOffset, self.offsetPosition!.y)
            let action = SCNAction.move(to: SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08 + altitudeOffset, self.offsetPosition!.y), duration: 1)
            mainPlaneNode.runAction(action)
        } else {
        
        
            //Add an altitude offset if is in night mode as the map is less high res
            altitudeOffset = type == .Night ? -30.0 : 0.0
            mainPlaneNode.removeAllActions()
            let index = waypoints.index { (waypoint) -> Bool in
                return waypoint.lat == offsetPosition?.lat && waypoint.long == offsetPosition?.long
            }
            
            let action = SCNAction.move(to: SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08 + altitudeOffset, self.offsetPosition!.y), duration: 1)
            mainPlaneNode.runAction(action)
            
            if index != nil {
                let mag = index!.magnitude
                let sub = Array(waypoints[Int(mag)...])
                nextLoc(sub.makeIterator())
            }
        }
        
    }
    
    private func addCities() {
        for city in cities {
            let billboard = Billboard(withName: city.name, englishName: city.englishName, position: city.position)
             mainPlaneNode.addChildNode(billboard.node)
        }
    }
    
    private func addLandmarks(){
        for landmark in landmarks {
            if let modelName = landmark.modelName, let landmarkModel = SCNScene(named: "3dmodels/\(modelName).scn"){
                landmarkModel.rootNode.position = landmark.position
                landmarkModel.rootNode.name = "landmark-\(landmark.name)"
                landmarkModel.rootNode.scale = SCNVector3(scaleConstant, scaleConstant, scaleConstant)
                mainPlaneNode.addChildNode(landmarkModel.rootNode)
            } else {
                print("No model for landmark")
            }
        }
    }
    
    
    //Start Flights
    func startFlight(){
        nextLoc(waypoints.makeIterator())
    }
    
    private func nextLoc(_ iterator: IndexingIterator<[Waypoint]>){
        var iterator = iterator
        if let next = iterator.next() {
            self.offsetPosition = next
            
            let action = SCNAction.move(to: SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08 + altitudeOffset, self.offsetPosition!.y), duration: 5)
            mainPlaneNode.runAction(action)
            
            locationTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { (_) in
                self.nextLoc(iterator)
            }
        }
    }
    
//    func updateLocation(_ location: CLLocation){
//        self.lastKnownDeviceLocation = location
//        self.deviceLocationUpdateTime = Date()
//        let lat = location.coordinate.latitude
//        let long = location.coordinate.longitude
//
//        let tilesStartCoordinate = tiles[0].origin
//        let distanceBetweenLat = -lat.distance(to: tilesStartCoordinate.0)
//        let distanceBetweenLong = -long.distance(to: tilesStartCoordinate.1)
//
//        mainPlaneNode.position.x = Float(distanceBetweenLat)
//        mainPlaneNode.position.z = Float(distanceBetweenLong)
//
//        /*
//        print("Device is at: \(lat, long) and firstTileIsAt \(tiles[0].startCoordinate)" )
//        print("Distance:", distanceBetweenLat, distanceBetweenLong)
//        print(mainPlaneNode.position)
//         */
//    }
}
