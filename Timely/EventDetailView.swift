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

    //let information: [String]
    
    var body: some View {
        /*
        let eventName = event.name ?? ""
        let eventEmoji = event.emoji ?? ""
        let eventTitle = eventName + eventEmoji
        */
        
        VStack {
            List {
                Section(header: Text("Info")) {
                    HStack {
                        Text(event.name ?? "Event Name")
                        Text(event.emoji ?? "📅")
                    }
                }
            }
            
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
        .navigationBarTitle(event.name ?? "Event Name", displayMode: .inline)
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
