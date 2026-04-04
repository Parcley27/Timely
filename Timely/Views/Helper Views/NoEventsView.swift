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
        .onAppear {
            startOneTimeTimer()
            
        }
    }
}

#Preview {
    NoEventsView(singleDayDisplay: false)
    //NoEventsView(singleDayDisplay: true)
    
}

