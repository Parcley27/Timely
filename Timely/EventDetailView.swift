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
        
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            //let navigationTitleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
            let navigationTitleWrapper = (event.name ?? "Details")
            
            VStack {
                Spacer()
                
                let titleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
                
                Text(titleWrapper)
                    .font(.largeTitle)
                    .bold()
                
                Text(event.timeUntil + timeUpdater)
                    .font(.title)
                    .onReceive(timer) { _ in
                        // Reset timeUpdater every second
                        // This tricks the text object into getting a new timeUntil
                        timeUpdater = " "
                        timeUpdater = ""
                    }
                    .foregroundStyle(event.timeUntil.hasPrefix("-") == true ? .red : .primary)
                    .bold(event.timeUntil.hasPrefix("-") == true)

                
                List {
                    Section("Date") {
                        Text(data.dateDisplayString(event: event))
                        //Text(data.timeUntil(inputDate: event.dateAndTime, format: "Seconds"))
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
            .navigationBarTitle(navigationTitleWrapper, displayMode: .inline)
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
