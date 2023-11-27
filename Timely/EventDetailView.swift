//
//  EventDetailView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-06.
//

import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var data: EventData
    
    let event: Event
        
    @State private var dateDisplayText: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            let navigationTitleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
            
            VStack {
                Spacer()
                
                let titleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
                
                Text(titleWrapper)
                    .font(.largeTitle)
                    .bold()
                
                Text(dateDisplayText)
                    .font(.title)
                    .onAppear() {
                        dateDisplayText = data.timeUntil(inputDate: event.dateAndTime)
                    }
                    .onReceive(timer) { _ in
                        // Update the date text every second
                        dateDisplayText = data.timeUntil(inputDate: event.dateAndTime)
                    }
                
                List {
                    Section("Date") {
                        Text(data.dateDisplayString(event: event))
                    }
                }
                .listStyle(.inset)
                
                /*
                 Button("Change name") {
                 let newName = "newName test"
                 data.updateEventName(event: event, newName: newName)
                 
                 }
                 */
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        print("Edit event")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .navigationBarTitle(event.name ?? "", displayMode: .inline)
        }
    }
}

struct EventDetailViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event"),
        ]

        return EventDetailView(event: previewData.events[0])
               .environmentObject(previewData)
    }
}
