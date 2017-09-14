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

func createDialogue(title: String, message: String, parentViewController: UIViewController) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let cancelAction = UIAlertAction(title: "Okay",
                                     style: .cancel, handler: nil)
    alert.addAction(cancelAction)
    parentViewController.present(alert, animated: true)
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



