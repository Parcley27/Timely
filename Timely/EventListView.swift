//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation

struct noEventsView: View {
    @Binding var data: [Event]
    
    @State private var showingSheet = false
    
    var body: some View {
        VStack {
            Text("No Saved Events")
                .font(.title2)
                .bold()
            
            Button() {
                showingSheet.toggle()
            
            } label: {
                HStack {
                    Text("Add a New Event")
                    Image(systemName: "plus")
                }
            }
                .sheet(isPresented: $showingSheet, content: {
                    NewEventSheetView(data: $data)
                })
        }
    }
}

struct EventListView: View {
    @Binding var data: [Event]
    @Environment(\.scenePhase) private var scenePhase
    
    let saveAction: ()->Void
    
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
            return AnyView(Button(action: showNewEventSheetView) { Image(systemName: "plus.circle") })
        default:
            return AnyView(EmptyView())
        }
    }
    
    func favouriteStatusIcon(event: Event) -> some View {
        var favouriteIcon: some View {
            Image(systemName: event.isFavourite == true ? "star.fill" : "star.slash.fill")
                .foregroundStyle(event.isFavourite == true ? .yellow : .gray)
        }
        
        return favouriteIcon
    }
    
    func mutedStatusIcon(event: Event) -> some View {
        var muteIcon: some View {
            Image(systemName: event.isMuted == true ? "bell.slash.fill" : "bell.fill")
                .foregroundStyle(event.isMuted == true ? .indigo : .gray)
        }
        
        return muteIcon
    }
    
    func listItem(event: Event) -> some View {
        HStack {
            Text(event.emoji ?? "📅")
                .font(.title)
            
            VStack(alignment: .leading) {
                Text(event.name ?? "Event Name")
                    .bold()
                
                HStack {
                    Text(event.timeUntil)
                        .font(.caption)
                        .onReceive(timer) { _ in
                            // Reset timeUpdater every second
                            // This tricks the text object into getting a new timeUntil
                            timeUpdater = " "
                            timeUpdater = ""
                        }
                        .foregroundStyle(event.hasPassed ? .red : .primary)
                        .bold(event.hasPassed)
                }
            }
            
            Spacer()
            
            HStack {
                favouriteStatusIcon(event: event)
                mutedStatusIcon(event: event)
            }
            .padding(.horizontal, 10)
        }
    }
    
    var listDisplay: some View {
        List {
            ForEach($data) { $event in
                NavigationLink(destination: EventDetailView(data: $data, event: $event)) {
                    listItem(event: event)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                event.isFavourite.toggle()
                                saveAction()
                                
                                print("Toggling favourite on \(event)")
                                
                            } label: {
                                if event.isFavourite == true {
                                    Label("Unfavourite", systemImage: "star.slash.fill")
                                } else {
                                    Label("Favourite", systemImage: "star.fill")
                                }
                            }
                            .tint(.yellow)
                        }
                    
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = $data.firstIndex(where: { $0.id == event.id }) {
                                    data.remove(at: index)
                                    saveAction()
                                }
                                print("Deleting \($event)")
                                
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            .tint(.red)
                            
                            if editMode == .inactive {
                                Button {
                                    event.isMuted.toggle()
                                    saveAction()
                                    
                                    print("Toggling mute on \(event)")
                                    
                                } label: {
                                    if event.isMuted == true {
                                        Label("Unmute", systemImage: "bell.fill")
                                    } else {
                                        Label("Mute", systemImage: "bell.slash.fill")
                                    }
                                }
                                .tint(.indigo)
                            }
                        }
                }
            }
            .onDelete { indexSet in
                data.remove(atOffsets: indexSet)
                saveAction()
            }
            .onMove { indices, newOffset in
                data.move(fromOffsets: indices, toOffset: newOffset)
                saveAction()
            }
        }
    }
        
    var body: some View {
        NavigationStack {
            VStack {
                if $data.count == 0 {
                    noEventsView(data: $data)
                } else {
                    listDisplay
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .disabled($data.count == 0)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .navigationBarTitle("Events")
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingSheet) {
                NewEventSheetView(data: $data)
                //.environmentObject(data)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .inactive {
                    saveAction()
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
            Event(name: "Sample Event 2", isMuted: true),
            Event(name: "Sample Event 3", isFavourite: true)
            // Add more sample events if needed
        ]
        
        let previewEvents = Binding.constant(previewData.events)

        return EventListView(data: previewEvents, saveAction: {})
    }
}
