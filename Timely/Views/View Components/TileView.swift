//
//  TileView.swift
//  Timely
//
//  Created by Pierce Oxley on 9/1/26.
//

// do listtinting off ones

import SwiftUI

struct TileView: View {
    //@Environment(\.colorScheme) var colorScheme
    //var isLightMode: Bool { colorScheme == .light }
    @State private var isLightMode: Bool
    
    var tileColours: [Color] = []
    let saturations: [Double] = [0.7, 0.8, 0.95]
    let brightnesses: [Double] = [1.25, 1.15, 0.95]
    let opacities: [Double] = [0.45, 0.45, 0.45]
    
    let forceBackground: Bool
    let saturationModifier: CGFloat
    let showBorder: Bool
    let cornerRadius: CGFloat
    
    init(inputColours: Color..., forceBackground: Bool = false, saturationModifier: CGFloat = 1, customBorder: Bool = true, cornerRadius: CGFloat = 24, isLightMode: Bool = true) {
        let baseColours = inputColours.isEmpty ? [.blue] : inputColours
        
        let colours = baseColours.count < saturations.count
                ? Array(repeating: baseColours[0], count: saturations.count)
                : baseColours
        
        self.forceBackground = forceBackground
        self.saturationModifier = saturationModifier
        self.showBorder = customBorder
        self.cornerRadius = cornerRadius
        
        self.isLightMode = isLightMode
        
        for (index, colour) in colours.enumerated() {
            guard index < saturations.count else { break }
            
            let adjustedBrightness = brightnesses[index] - (isLightMode ? 0 : 0.25)
            
            if colour.isGreyscale {
                tileColours.append(
                    colour.asGreyscale(
                        brightness: adjustedBrightness,
                        opacity: opacities[index] * saturationModifier
                        
                    )
                )
                
            } else {
                tileColours.append(
                    colour.adjusted(
                        saturation: saturations[index],
                        brightness: adjustedBrightness,
                        opacity: opacities[index] * saturationModifier
                        
                    )
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
            if forceBackground {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .foregroundStyle(isLightMode ? .white : .black)
                
            }
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .foregroundStyle(
                    LinearGradient(
                        colors: tileColours,
                        startPoint: .top,
                        endPoint: .bottom
                        
                    )
                )
                .brightness(tileColours[0].isGreyscale && !isLightMode ? -0.6 : 0)
            
            if showBorder {
                let lastTileColour = tileColours.last!
                let borderBrightness = brightnesses.last! - (isLightMode ? 0 : 0.25)
                let borderColour = lastTileColour.isGreyscale
                    ? lastTileColour.asGreyscale(brightness: borderBrightness, opacity: 1.0)
                    : lastTileColour.adjusted(saturation: 0.95, brightness: borderBrightness)
                
//                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                    .stroke(
//                        LinearGradient(
//                        colors: [borderColour, Color.clear, Color.clear, Color.clear, borderColour],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                        
//                        ),
//                        
//                        lineWidth: 2
//                    )
//                    //.brightness(-0.2) // -1 ... 1
                
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColour, lineWidth: 1)
                
            }
        }
    }
}

#Preview {
    let cornerRadius: CGFloat = 24
    
    ZStack {
        //Text("asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfsadfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf")
        TileView(inputColours: .black, customBorder: true, cornerRadius: cornerRadius)
            .frame(maxWidth: 300, maxHeight: 100)
        
        Text("Hello, TileView!")
        
    }
    .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: cornerRadius))
    
}
