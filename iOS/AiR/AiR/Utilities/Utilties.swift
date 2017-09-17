//
//  Utilties.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

let scaleConstant: Double = 0.0001

//Conversion from Lat/Long to and from Mercator x and y coordinates
let sm_a = 6378137.0
let sm_b = 6378301.898519918

func latLongToWGS84(lat: Double, long: Double, isDeg: Bool = true) -> (Double, Double){
    
    var latitude = lat
    var longitude = long
    
    let long0 = 0.0
    if isDeg {
        latitude = degreesToRadians(lat)
        longitude = degreesToRadians(long)
    }
    
    let x = sm_a * (longitude - long0)
    let y = sm_b * log((1 + sin(latitude)) / (1 - sin(latitude))) / 2
    
    return (x, y)
}

func WGS84ToLatLong(x: Double, y: Double, inDeg: Bool = true) -> (Double, Double){
    let long0 = 0.0
    var long = x / sm_a + long0
    var lat = sin((exp(2 * y / sm_b) - 1) / (exp(2 * y / sm_b) + 1))
    
    if inDeg {
        lat = radiansToDegrees(lat)
        long = radiansToDegrees(long)
    }
    
    return (lat, long)
}

func degreesToRadians(_ degrees: Double) -> Double {
    return degrees * Double.pi/180
}

func radiansToDegrees(_ radians: Double) -> Double {
    return radians / Double.pi * 180.0
}







func createDialogue(title: String, message: String, parentViewController: UIViewController, dismissOnCompletion: Bool) {
    DispatchQueue.main.async(execute: {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Okay",
                                         style: .cancel,
                                         handler: {_ in if dismissOnCompletion { parentViewController.dismiss(animated: true, completion: nil) } })
        alert.addAction(cancelAction)
        parentViewController.present(alert, animated: true)
    })
}

func map(regex: String, to text: String) -> Bool {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return results.count > 0
    } catch let error {
        print("Invalid regex: \(error.localizedDescription)")
        return false
    }
}

public func cacheImage(image: UIImage, name: String){
    let components = name.components(separatedBy: "/")
    let flightID = components[4]
    let tileName = components[5]
    
    let fileURL = getDocumentsDirectory().appendingPathComponent("tile-\(flightID)-\(tileName).jpg")
    
    if let data = UIImageJPEGRepresentation(image, 1) {
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("Error whilst caching \(error)")
        }
    }
}



public func getDocumentsDirectory() -> URL {
    return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
}

public func getFromCache(name: String) -> UIImage? {
    let components = name.components(separatedBy: "/")
    let flightID = components[4]
    let tileName = components[5]
    
    let fileURL = getDocumentsDirectory().appendingPathComponent("tile-\(flightID)-\(tileName).jpg")
    do {
        let data = try Data(contentsOf: fileURL)
        if let image = UIImage(data: data) {
            return image
        } else {
            return nil
        }
    } catch {
        return nil
    }
}

extension UIViewController {
    func sizeClass() -> (UIUserInterfaceSizeClass, UIUserInterfaceSizeClass) {
        return (self.traitCollection.horizontalSizeClass, self.traitCollection.verticalSizeClass)
    }
}
