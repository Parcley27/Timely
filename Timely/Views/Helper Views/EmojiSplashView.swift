//
//  EmojiSplashView.swift
//  Timely
//
//  Created by Pierce Oxley on 2/2/26.
//

import SwiftUI
import Foundation

struct EmojiSplashView: View {
    let emoji: String
    let colour: Color
    
    let size: CGFloat
    let angle: Double
    
    let height: Int
    let width: Int
    
    init(emoji: String = "➡️", colour: Color = Color.blue, size: CGFloat = 75, angle: Double = 10, height: Int = 10, width: Int = 8) {
        self.emoji = emoji
        self.colour = colour
        
        self.size = size
        self.angle = angle
        
        self.height = height
        self.width = width
        
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: size / 2) {
            ForEach(0 ..< height, id: \.self) { _ in
                HStack(spacing: size / 2) {
                    ForEach(0 ..< width, id: \.self) { _ in
                        Text(emoji)
                            .font(.system(size: size))
                            .fixedSize()
                            .shadow(color: colour, radius: size / 10)
                        
                    }
                }
            }
        }
        .rotation3DEffect(.degrees(45), axis: (x: 1, y: 0, z: 0))
        .rotationEffect(.degrees(angle), anchor: .center)
        
    }
}

#Preview {
    EmojiSplashView()
    
}
