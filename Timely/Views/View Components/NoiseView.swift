//
//  NoiseView.swift
//  Timely
//
//  Created by Pierce Oxley on 27/10/25.
//

import SwiftUI

struct NoiseView: View {
    var intensity: Double = 0.12
    var noiseScale: Double = 1.5
    var contrast: Double = 1.6
    
    init(intensity: Double = 0.12, noiseScale: Double = 1.5, contrast: Double = 1.6) {
        self.intensity = intensity
        self.noiseScale = noiseScale
        self.contrast = contrast
        
    }
    
    var body: some View {
        ZStack {
            // The actual noise - generated once and tiled
            GeometryReader { geometry in
                Image(uiImage: NoiseTextureGenerator.shared.noiseTexture)
                    .resizable(resizingMode: .tile)
                    .scaleEffect(noiseScale)
                    .contrast(contrast)
                    .opacity(intensity)
                    .allowsHitTesting(false)
                
            }
        }
    }
}

class NoiseTextureGenerator {
    static let shared = NoiseTextureGenerator()
    
    let noiseTexture: UIImage
    
    private init() {
        // Generate noise texture once on init
        self.noiseTexture = Self.generateNoiseTexture()
        
    }
    
    private static func generateNoiseTexture(size: CGSize = CGSize(width: 128, height: 128)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Create noise pattern
            for x in 0..<Int(size.width) {
                for y in 0..<Int(size.height) {
                    // Random grayscale value
                    let brightness = CGFloat.random(in: 0...1)
                    let alpha = CGFloat.random(in: 0.1...0.3)
                    
                    cgContext.setFillColor(UIColor(white: brightness, alpha: alpha).cgColor)
                    cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Text("hi")
        Color.blue
        Text("hello")
        NoiseView()
        
    }
}
