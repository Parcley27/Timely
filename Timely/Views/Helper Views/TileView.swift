//
//  TileView.swift
//  Timely
//
//  Created by Pierce Oxley on 9/1/26.
//

import SwiftUI

struct TileView: View {
    var tileColours: [Color] = []
    let colourOpacities: [Double] = [0.45, 0.45, 0.45]
    
    let showBorder: Bool
    let cornerRadius: CGFloat
    
    init(inputColours: [Color] = [.blue, .red], showBorder: Bool = true, cornerRadius: CGFloat = 24) {
        let colours = inputColours.isEmpty ? [.blue] : inputColours
        
        let repeatingColours = colours.count < colourOpacities.count
            ? Array(repeating: colours[0], count: colourOpacities.count)
            : colours
        
        tileColours = zip(repeatingColours, colourOpacities)
            .map { $0.opacity($1) }
        
        self.showBorder = showBorder
        self.cornerRadius = cornerRadius
        
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
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(tileColours.last!.opacity(0.6), lineWidth: 2)
                    .brightness(-0.2) // -1 ... 1
                

                
            }
        }
    }
}

#Preview {
    TileView(inputColours: [.blue, .teal, .green], showBorder: true, cornerRadius: 24)
        .frame(maxWidth: 200, maxHeight: 200)
    
}
