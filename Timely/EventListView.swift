//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI

import Foundation

struct EventListView: View {
    @EnvironmentObject var data: EventData
    
    @State private var showingSheet = false

    var body: some View {
        VStack{
            NavigationStack {
                VStack {
                    if data.events.count == 0 {
                        Spacer()
                        
                        Button {
                            showingSheet.toggle()
                        } label: {
                            Label("Add New Event", systemImage: "plus")
                                .font(.title2)
                        }
                        .sheet(isPresented: $showingSheet) {
                            NewEventSheetView().environmentObject(data)
                        }
                        
                        Spacer()
                        
                    } else {
                        List{
                            ForEach(data.events) { event in
                                NavigationLink(destination: EventDetailView(event: event).environmentObject(data)) {
                                    HStack {
                                        Text(event.emoji ?? "📅")
                                        Text("")
                                        
                                        VStack {
                                            Text(event.name ?? "EventName")
                                                .bold()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            /*
                                            Text(event.date ?? "2007/06/29")
                                                .font(.caption)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                             */
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
                        EditButton()
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
                
                .navigationBarTitle("Events", displayMode: .inline)
            }
        }
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
           let previewData = EventData() // Assuming EventData conforms to ObservableObject
           previewData.events = [
               Event(name: "Sample Event 1"),
               Event(name: "Sample Event 2"),
               // Add more sample events as needed
           ]

           return EventListView()
               .environmentObject(previewData)
       }
}
