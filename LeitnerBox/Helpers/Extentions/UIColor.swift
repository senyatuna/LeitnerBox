//
//  UIColor.swift
//  ChatApplication
//
//  Created by hamed on 4/12/22.
//

import Foundation
import UIKit

extension UIColor{
    
    static func random() -> UIColor {
        return UIColor(
            red   : .random(in : 0...1),
            green : .random(in : 0...1),
            blue  : .random(in : 0...1),
            alpha : 1.0
        )
    }

    func isLight(threshold: Float = 0.7) -> Bool? {
        let originalCGColor = self.cgColor
        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }
        
        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
    }
}

