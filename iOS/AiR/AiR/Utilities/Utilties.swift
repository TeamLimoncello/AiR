//
//  Utilties.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

func degreesToRadians(_ degrees: Float) -> Float {
    return degrees * Float.pi/180
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
    
    let fileURL = getDocumentsDirectory().appendingPathComponent("tile-\(flightID)-\(tileName)")
    print("Saving to \(fileURL)")
    
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
    
    let fileURL = getDocumentsDirectory().appendingPathComponent("tile-\(flightID)-\(tileName)")
    print("Getting from \(fileURL)")
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
