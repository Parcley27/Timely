//
//  NoEventsView.swift
//  Timely
//
//  Created by Pierce Oxley on 4/4/26.
//

import SwiftUI

struct NoEventsView: View {
    var singleDayDisplay: Bool
    
    @State private var displayText = NSLocalizedString("Loading...", comment: "")
    @State private var opacity: Double = 0.0
    
    private func startOneTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            displayText = NSLocalizedString("No Saved Events", comment: "")
            
        }
    }
    
    var body: some View {
        VStack {
            if singleDayDisplay {
                Text("No Events")
                    .font(.title2)
                    .bold()
                
            } else {
                Text(displayText)
                    .font(.title2)
                    .bold()
                
            }
        }
        .opacity(opacity)
        .onAppear {
            startOneTimeTimer()
            
            // Fade in after 1 second, taking 2 seconds to complete
            withAnimation(.easeIn(duration: 2.0).delay(1.0)) {
                opacity = 1.0
                
            }
        }
    }
}

#Preview {
    NoEventsView(singleDayDisplay: false)
    //NoEventsView(singleDayDisplay: true)
    
}

