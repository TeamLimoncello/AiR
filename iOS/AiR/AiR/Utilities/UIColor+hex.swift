//
//  UIColor+hex.swift
//  AiR
//
//  Created by Jay Lees on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static func hexToRGB(hex: String) -> UIColor? {
        let array = hex.characters.map {String($0)}
        if array.count == 6 {
            if let red = UInt8("\(array[0])\(array[1])", radix: 16), let green = UInt8("\(array[2])\(array[3])", radix: 16), let blue = UInt8("\(array[4])\(array[5])", radix: 16) {
                return UIColor(red: CGFloat(red)/255, green: CGFloat(green)/255, blue: CGFloat(blue)/255, alpha: 1)
            }
        }
        return nil
    }
}
