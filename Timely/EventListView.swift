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
    
    @State private var isEditing =  false
    @State private var editMode = EditMode.inactive

    @State private var showingSheet = false
    
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        
    func showNewEventSheetView() {
        showingSheet = true
    }
    
    private var addButton: some View {
        switch editMode {
        case .inactive:
            return AnyView(Button(action: showNewEventSheetView) { Image(systemName: "plus") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    func favouriteStatusIcon(event: Event) -> some View {
        var favouriteIcon: some View {
            Button {
                data.toggleFavouriteEvent(event: event)
            } label: {
                if event.isFavourite == true {
                    Label("", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                } else {
                    Label("", systemImage: "star.slash")
                        .foregroundStyle(.gray)
                }
            }
        }
        
        return favouriteIcon
    }
    
    func mutedStatusIcon(event: Event) -> some View {
        var muteIcon: some View {
            Button {
                data.toggleMutedEvent(event: event)
            } label: {
                if event.isMuted == true {
                    Label("", systemImage: "bell.fill")
                        .foregroundStyle(.indigo)
                } else {
                    Label("", systemImage: "bell.slash")
                        .foregroundStyle(.gray)
                }
            }
        }
        
        return muteIcon
    }

    var body: some View {
        let listDisplay = List {
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
                            
                            HStack {
                                Text(event.timeUntil + timeUpdater)
                                    .font(.caption)
                                    .onReceive(timer) { _ in
                                        // Reset timeUpdater every second
                                        // This tricks the text object into getting a new timeUntil
                                        timeUpdater = " "
                                        timeUpdater = ""
                                    }
                                    .foregroundStyle(event.timeUntil.hasPrefix("-") == true ? .red : .primary)
                                    .bold(event.timeUntil.hasPrefix("-") == true)
                            }
                        }
                        
                        Spacer()
                        
                        favouriteStatusIcon(event: event)
                        mutedStatusIcon(event: event)
                        
                        Text("")
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        
                        Button {
                            data.toggleFavouriteEvent(event: event)
                            print("Toggling favourite on \(event)")
                        } label: {
                            if event.isFavourite == true {
                                Label("Unfavourite", systemImage: "star")
                            } else {
                                Label("Favourite", systemImage: "star.slash")
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
        //.listStyle(.inset)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if data.events.count != 0 {
                    EditButton()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .navigationBarTitle("Upcoming")
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingSheet) {
            NewEventSheetView()
                .environmentObject(data)
        }
        
        NavigationStack {
            VStack {
                if data.events.count == 0 {
                    noEventsView()
                } else {
                    listDisplay
                }
            }
        }
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
            Event(name: "Sample Event 2"),
            // Add more sample events if needed
        ]

        return EventListView()
            .environmentObject(previewData)
    }
}
