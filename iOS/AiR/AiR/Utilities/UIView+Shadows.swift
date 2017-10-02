//
//  Shadows.swift
//  AiR
//
//  Created by Brendon Warwick on 12/09/2017.
//  Copyright © 2017 lemoncello. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    enum ShadowIntensity: CGFloat {
        case Weak = 8.0
        case Ehh = 28.0
        case ChristianBale = 40.0
    }
    
    func addShadow(intensity: ShadowIntensity) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = intensity.rawValue
        self.layer.shadowOpacity = intensity == .Weak ? 0.45 : 0.65
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    func removeShadow() {
        self.layer.shadowColor = UIColor.clear.cgColor
    }
}
