//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation

struct noEventsView: View {
    var singleDayDisplay: Bool
    var body: some View {
        VStack {
            Text(singleDayDisplay ? "No Events" : "No Upcoming Events")
                .font(.title2)
                .bold()
            
        }
    }
}

struct EventListView: View {
    @Binding var data: [Event]
    var dateToDisplay: Date?
    let saveAction: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isEditing =  false
    @State private var editMode = EditMode.inactive
    
    @State private var showingSheet = false
    @State private var confirmationIsShowing = false
    
    @State var showMuted = true
    @State var showStandard = true
    @State var showFavourite = true

    
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            
    func showNewEventSheetView() {
        showingSheet = true
        
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
    
    func compareDates(event: Event, date: Date?) -> Bool {
        if date != nil {
            let eventDay = Calendar.current.component(.day, from: event.dateAndTime)
            let eventMonth = Calendar.current.component(.month, from: event.dateAndTime)
            let eventYear = Calendar.current.component(.year, from: event.dateAndTime)
            
            let dateDay = Calendar.current.component(.day, from: date!)
            let dateMonth = Calendar.current.component(.month, from: date!)
            let dateYear = Calendar.current.component(.year, from: date!)
            
            if eventDay == dateDay && eventMonth == dateMonth && eventYear == dateYear {
                return true
                
            } else {
                return false
                
            }
            
        } else {
            return false
            
        }
    }
    
    func formatStringForDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .medium
        
        //dateFormatter.dateFormat = "h:mm a 'on' EEEE, MMMM d, yyyy"
        
        let dateString = dateFormatter.string(from: date)
        
        return dateString
        
    }
    
    var eventsToShow: Int {
        var agreeingEvents = 0
        
        if dateToDisplay != nil {
            for event in data {
                if compareDates(event: event, date: dateToDisplay ?? nil) {
                    agreeingEvents += 1
                    
                }
            }
            
        } else {
            for _ in data {
                agreeingEvents += 1
                
            }
        }
        
        return agreeingEvents
        
    }
    
    func listItem(event: Event) -> some View {
        HStack {
            ZStack {
                Text("📅")
                    .font(.title)
                    .opacity(0)
                
                Text(event.emoji ?? "📅")
                    .font(.title)
                
            }
            
            VStack(alignment: .leading) {
                Text(event.name ?? "Event Name")
                    .font(.title3)
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
    
    func shouldDisplay(event: Event, dateToDisplay: Date?) -> Bool {
        if dateToDisplay == nil {
            if SettingsStore().removePassedEvents == false {
                return true
                
            } else if SettingsStore().removePassedEvents == true {
                if event.hasExpired() == false {
                    return true
                    
                } else if event.hasExpired() == true {
                    return false
                    
                }
            }
            
        } else {
            if compareDates(event: event, date: dateToDisplay) {
                return true
                
            }
        }
        
        return false
        
    }
    
    var listDisplay: some View {
        List {
            ForEach($data) { $event in
                let index = $data.firstIndex(where: { $0.id == event.id })
                
                if shouldDisplay(event: event, dateToDisplay: dateToDisplay) {
                    
                    if (showFavourite || !event.isFavourite) && (showMuted || !event.isMuted) && (showStandard || event.isFavourite || event.isMuted) {
                        
                        NavigationLink(destination: EventDetailView(data: $data, event: index!)) {
                            listItem(event: event)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        if let index = $data.firstIndex(where: { $0.id == event.id }) {
                                            data[index].isFavourite.toggle()
                                            Task {
                                                do {
                                                    try await EventStore().save(events: data)
                                                    
                                                } catch {
                                                    fatalError(error.localizedDescription)
                                                    
                                                }
                                            }
                                        }
                                        
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
                                            
                                            Task {
                                                do {
                                                    try await EventStore().save(events: data)
                                                    
                                                } catch {
                                                    fatalError(error.localizedDescription)
                                                    
                                                }
                                            }
                                        }
                                        print("Deleting \($event)")
                                        
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                        
                                    }
                                    .tint(.red)
                                    
                                    if editMode == .inactive {
                                        Button {
                                            if let index = $data.firstIndex(where: { $0.id == event.id }) {
                                                data[index].isMuted.toggle()
                                                Task {
                                                    do {
                                                        try await EventStore().save(events: data)
                                                        
                                                    } catch {
                                                        fatalError(error.localizedDescription)
                                                        
                                                    }
                                                }
                                            }
                                            
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
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let event = data[index]
                    
                    EventStore().removeNotifications(for: event)
                    
                }
                
                data.remove(atOffsets: indexSet)
                data.sort(by: { $0.dateAndTime < $1.dateAndTime })
                
                Task {
                    do {
                        try await EventStore().save(events: data)
                        
                    } catch {
                        fatalError(error.localizedDescription)
                        
                    }
                    
                }
            }
        }
    }
        
    var body: some View {
        NavigationStack {
            VStack {
                if eventsToShow == 0 {
                    noEventsView(singleDayDisplay: dateToDisplay != nil ? true : false)
                    
                } else {
                    listDisplay
                    
                }
            }
            .toolbar {
                if eventsToShow != 0 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showFavourite.toggle()
                                
                            } label: {
                                if showFavourite == true {
                                    Label("Hide Favourite Events", systemImage: "star")
                                    
                                } else {
                                    Label("Show Favourite Events", systemImage: "star")
                                    
                                }
                            }
                            
                            Button {
                                showStandard.toggle()
                                
                            } label: {
                                if showStandard == true {
                                    Label("Hide Standard Events", systemImage: "calendar")
                                    
                                } else {
                                    Label("Show Standard Events", systemImage: "calendar")
                                    
                                }
                            }
                            
                            Button {
                                showMuted.toggle()
                                
                            } label: {
                                if showMuted == true {
                                    Label("Hide Muted Events", systemImage: "bell.slash")
                                    
                                } else {
                                    Label("Show Muted Events", systemImage: "bell.slash")
                                    
                                }
                            }
                            
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            
                        }
                        .disabled(editMode .isEditing ? true : false)
                        
                    }
                }
            }
            .navigationBarTitle(dateToDisplay != nil ? formatStringForDate(date: dateToDisplay!) : "Events")
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingSheet) {
                NewEventSheetView(data: $data)
            }
            .onChange(of: scenePhase) { phase in
                if phase == .inactive {
                    Task {
                        do {
                            try await EventStore().save(events: data)
                            
                        } catch {
                            fatalError(error.localizedDescription)
                            
                        }
                    }
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
