//
//  TileView.swift
//  Timely
//
//  Created by Pierce Oxley on 9/1/26.
//

import SwiftUI

struct TileView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var isLightMode: Bool { colorScheme == .light }
    
    var tileColours: [Color] = []
    let saturations: [Double] = [0.7, 0.8, 0.95]
    let brightnesses: [Double] = [1.25, 1.15, 0.95]
    let opacities: [Double] = [0.45, 0.45, 0.45]
    
    
    let showBorder: Bool
    let cornerRadius: CGFloat
    
    init(inputColours: Color..., customBorder: Bool = false, cornerRadius: CGFloat = 24) {
        let baseColours = inputColours.isEmpty ? [.blue] : inputColours
        
        let colours = baseColours.count < saturations.count
                ? Array(repeating: baseColours[0], count: saturations.count)
                : baseColours
        
        self.showBorder = customBorder
        self.cornerRadius = cornerRadius
        
        for (index, colour) in colours.enumerated() {
            guard index < saturations.count else { break }
            
            tileColours.append(
                colour.adjusted(
                    saturation: saturations[index],
                    brightness: brightnesses[index] - (isLightMode ? 0 : 0.25),
                    opacity: opacities[index]
                    
                )
            )
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .foregroundStyle(
                    LinearGradient(
                        colors: tileColours,
                        startPoint: .top,
                        endPoint: .bottom
                        
                    )
                )
            
            if showBorder {
                let borderColour = tileColours.last!.adjusted(saturation: 0.95, brightness: brightnesses.last! - (isLightMode ? 0 : 0.25))
                
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                        colors: [borderColour, Color.clear, Color.clear, Color.clear, borderColour],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                        
                        ),
                        
                        lineWidth: 2
                    )
                    //.brightness(-0.2) // -1 ... 1
            }
        }
    }
}

#Preview {
    let cornerRadius: CGFloat = 24
    
    ZStack {
        //Text("asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfsadfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf")
        TileView(inputColours: .blue, customBorder: true, cornerRadius: cornerRadius)
            .frame(maxWidth: 300, maxHeight: 100)
        
        Text("Hello, TileView!")
        
    }
    .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: cornerRadius))
    
}
