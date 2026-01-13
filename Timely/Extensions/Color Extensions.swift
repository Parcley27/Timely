//
//  Color Extensions.swift
//  Timely
//
//  Created by Pierce Oxley on 12/1/26.
//

import Foundation
import SwiftUI
import UIKit

extension Color {
    var isGreyscale: Bool {
        let uiColour = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColour.getRed(&red, green: &green, blue: &blue, alpha: &alpha) // Within range of 0 ... 1
        
        let maxComponent = max(red, green, blue)
        let minComponent = min(red, green, blue)
        
        let colourDifference = maxComponent - minComponent
        
        return colourDifference < 0.01
        
    }
    
    func adjusted(saturation: Double? = nil, brightness: Double? = nil, opacity: Double? = nil) -> Color {
        let uiColour = UIColor(self)
                
        var hue: CGFloat = 0
        var saturationComponent: CGFloat = 0
        var brightnessComponent: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColour.getHue(&hue, saturation: &saturationComponent, brightness: &brightnessComponent, alpha: &alpha)
        
        let newSaturation: CGFloat = saturation.map { CGFloat($0) } ?? saturationComponent
        let newBrightness: CGFloat = brightness.map { CGFloat($0) } ?? brightnessComponent
        let newAlpha: CGFloat = opacity.map { CGFloat($0) } ?? alpha
        
        return Color(
            hue: Double(hue),
            saturation: Double(newSaturation.clamped(to: 0...1)),
            brightness: Double(newBrightness.clamped(to: 0...1)),
            opacity: Double(newAlpha.clamped(to: 0...1))
            
        )
    }
    
    func asGreyscale(brightness: Double, opacity: Double) -> Color {
        let uiColour = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let greyValue = (Double(red) + Double(green) + Double(blue)) / 3.0
        
        // Map brightness parameter to min - max range
        let minGrey = 0.3 + (brightness * 0.58)
        let maxGrey = 0.93 + (brightness * 0.07)
        
        let adjustedGrey = (greyValue * brightness).clamped(to: minGrey...maxGrey)
        
        return Color(
            red: adjustedGrey,
            green: adjustedGrey,
            blue: adjustedGrey,
            opacity: opacity
            
        )
    }
}
