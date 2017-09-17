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
    
    init(deviceHeading: Float, path: Path){
        self.tiles = path.tiles
        self.cities = path.cities
        self.landmarks = path.landmarks
        self.waypoints = path.waypoints
        mainPlane = SCNPlane(width: 10, height: 10)
        mainPlane.firstMaterial?.diffuse.contents = UIColor.clear
        mainPlaneNode = SCNNode(geometry: mainPlane)
        //Rotates into the correct plane
        mainPlaneNode.eulerAngles.x = Float(degreesToRadians(-90))
        //mainPlaneNode.eulerAngles.y = degreesToRadians(deviceHeading + headingOfFlight)
        
        //Moves the device 70 meters into the air
        mainPlaneNode.position = SCNVector3(x: 0, y: -1, z: 0)
        
        addTiles()
        addCities()
        addLandmarks()
    }
    
    
    
    /*
     Notes:
         X-Axis is right(+) and left(-)
         Y-Axis is backwards(-) and forwards(+)
         Z-Axis is closer to camera(+) and further away(-)
 
     */
    func addTiles() {
        tiles.filter({$0.tileType == .Day}).forEach({
            let x = $0.origin.x + ($0.size.w/2)
            let y = -$0.origin.y + ($0.size.h/2)
            
            $0.setPosition(SCNVector3(x: Float(x), y: Float(y), z: 0))
            mainPlaneNode.addChildNode($0.node)
        })
     
        self.offsetPosition = waypoints.first
        self.mainPlaneNode.position = SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08, self.offsetPosition!.y)
        
        print(tiles.filter({$0.tileType == .Day})[0].node.position)
        print(mainPlaneNode.position)
       
    }
    
    func startFlight(){
        nextLoc(waypoints.makeIterator())
        
    }
    
    func nextLoc(_ iterator: IndexingIterator<[Waypoint]>){
        var iterator = iterator
        if let next = iterator.next() {
            self.offsetPosition = next
            
            let action = SCNAction.move(to: SCNVector3(-self.offsetPosition!.x, Double(-self.offsetPosition!.altitude) / 328.08, self.offsetPosition!.y), duration: 1)
            mainPlaneNode.runAction(action)
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
                self.nextLoc(iterator)
            }
        }
    }
    
    func addCities() {
        for city in cities {
            // let billboard = Billboard(with: city.englishName, position: city.position)
            // mainPlaneNode.addChildNode(billboard)
        }
    }
    
    func addLandmarks(){
        //TODO: Fully implement
        // same as landmarks?
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
