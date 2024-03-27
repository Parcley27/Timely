//
//  CalendarView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-03-25.
//

import SwiftUI

struct CalendarView: View {
    @Binding var data: [Event]
    
    let saveAction: ()->Void
    
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, Calendar!")

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button() {
                        // SHOW TODAY VIEW
                    } label: {
                        Text("Today")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button() {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                Settings(data: $data)
            }
            .navigationBarTitle("Calendar")
            
        }
    }
}

#Preview {
    let previewData = EventData()
    previewData.events = [
        Event(name: "Sample Event 1", dateAndTime: Date()),
        Event(name: "Sample Event 2", isMuted: true),
        Event(name: "Sample Event 3", isFavourite: true)
        // Add more sample events if needed
    ]
    
    let previewEvents = Binding.constant(previewData.events)
    
    return CalendarView(data: previewEvents, saveAction: {})
}
