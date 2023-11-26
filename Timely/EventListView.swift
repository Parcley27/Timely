//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation

struct noEventsView: View {
    @EnvironmentObject var data: EventData
    
    @State private var showingSheet = false
    
    var body: some View {
        Spacer()
        
        Button() {
            showingSheet.toggle()
        
        } label: {
            Label("Add New Event", systemImage: "plus")
                .font(.title)
        }
        .sheet(isPresented: $showingSheet, content: {
            NewEventSheetView()
                .environmentObject(data)
        })
        
        Spacer()
    }
}

struct EventListView: View {
    @EnvironmentObject var data: EventData
    
    @State private var showingSheet = false
    
    @State private var dateDisplayText: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack {
                if data.events.count == 0 {
                    noEventsView()

                } else {
                    List{
                        ForEach(data.events) { event in
                            NavigationLink(destination: EventDetailView(event: event)
                                .environmentObject(data))
                            {
                                HStack {
                                    Text(event.emoji ?? "📅")
                                    Text("")
                                    
                                    VStack(alignment: .leading) {
                                        Text(event.name ?? "Event Name")
                                            .bold()
                                            //.frame(maxWidth: .infinity, alignment: .leading)
                                                                                
                                        Text(dateDisplayText)
                                            .font(.caption)
                                            .onReceive(timer) { _ in
                                                // Update the date text every second
                                                dateDisplayText = data.timeUntil(inputDate: event.dateAndTime)
                                            }
                                            //.frame(maxWidth: .infinity, alignment: .leading)

                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    
                                    Button {
                                        data.toggleFavouriteEvent(event: event)
                                        print("Toggling favourite on \(event)")
                                    } label: {
                                        if event.isFavourite == true {
                                            Label("Unfavourite", systemImage: "star.slash")
                                        } else {
                                            Label("Favourite", systemImage: "star")
                                        }
                                    }
                                    .tint(.yellow)
                                }
                                
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    
                                    Button(role: .destructive) {
                                        data.removeEvent(event: event)
                                        print("Deleting \(event)")
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    .tint(.red)
                                    
                                    Button {
                                        data.toggleMutedEvent(event: event)
                                        print("Toggling mute on \(event)")
                                    } label: {
                                        if event.isMuted == true {
                                            Label("Unmute", systemImage: "bell.slash.fill")
                                        } else {
                                            Label("Mute", systemImage: "bell.fill")
                                        }
                                    }
                                    .tint(.indigo)
                                }
                            }
                        }
                        .onDelete {
                            data.events.remove(atOffsets: $0)
                        }
                        .onMove {
                            data.events.move(fromOffsets: $0, toOffset: $1)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if data.events.count != 0 {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSheet.toggle()
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .sheet(isPresented: $showingSheet) {
                        NewEventSheetView()
                            .environmentObject(data)
                    }
                }
            }
            .navigationBarTitle("Upcoming", displayMode: .inline)
        }
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
           let previewData = EventData()
           previewData.events = [
               Event(name: "Sample Event 1"),
               Event(name: "Sample Event 2"),
               // Add more sample events if needed
           ]

           return EventListView()
               .environmentObject(previewData)
       }
}
