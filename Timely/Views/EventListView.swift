//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation

struct UniqueDate: Identifiable {
    var date: Date
    
    let id: UUID = UUID()
}

struct NoEventsView: View {
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
    
    @State private var newTimeUntilEvent: String = ""
    
    func calculateTime(event: Event) -> String {
        return event.timeUntil
        
    }
    
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
    
    var eventsToShow: [Event] {
        var agreeingEvents: [Event] = []
        
        if dateToDisplay != nil {
            for event in data {
                if compareDates(event: event, date: dateToDisplay){
                    agreeingEvents.append(event)
                    
                }
            }
            
        } else {
            for event in data {
                if shouldDisplay(event: event, dateToDisplay: dateToDisplay) {
                    agreeingEvents.append(event)
                    
                }
            }
        }
        
        return agreeingEvents
        
    }
    
    var uniqueDates: [UniqueDate] {
        var datesSeen: [UniqueDate] = []
        
        for event in eventsToShow {
            if (showFavourite || !event.isFavourite) && (showMuted || !event.isMuted) && (showStandard || !event.isStandard) {
                var isUnique = true
                
                for seenDate in datesSeen {
                    if compareDates(event: event, date: seenDate.date) {
                        isUnique = false
                        break
                        
                    }
                }
                
                if isUnique {
                    datesSeen.append(UniqueDate(date: event.dateAndTime))
                    
                }
            }
        }
        
        return datesSeen
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
    
    func eventTile(event: Event) -> some View {
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
    
    func listSection(for section: UniqueDate) -> some View {
        ForEach($data) { $event in
            
            let index = $data.firstIndex(where: { $0.id == event.id })
            
            if shouldDisplay(event: event, dateToDisplay: dateToDisplay) && shouldDisplay(event: event, dateToDisplay: section.date) {
                if (showFavourite || !event.isFavourite) && (showMuted || !event.isMuted) && (showStandard || !event.isStandard) {
                    
                    NavigationLink(destination: EventDetailView(data: $data, event: index!)) {
                        eventTile(event: event)
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
                        //.disabled(!isEditing)
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
    
    var listDisplay: some View {
        List {
            ForEach(uniqueDates) { UniqueDate in
                if dateToDisplay == nil {
                    Section(formatStringForDate(date: UniqueDate.date)) {
                        listSection(for: UniqueDate)
                        
                    }
                    
                } else {
                    listSection(for: UniqueDate)
                    
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if eventsToShow.isEmpty {
                    NoEventsView(singleDayDisplay: dateToDisplay != nil ? true : false)
                    
                } else {
                    listDisplay
                    
                }
            }
            /*
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                    
                }
            }
             */
            .toolbar {
                if !eventsToShow.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            /*
                            Button {
                                showFavourite.toggle()
                                
                            } label: {
                                if showFavourite == true {
                                    Label("Hide Favourite Events", systemImage: "star")
                                    
                                } else {
                                    Label("Show Favourite Events", systemImage: "star")
                                    
                                }
                            }
                            .disabled((showStandard || showMuted) == false)
                             */
                            
                            Button {
                                showStandard.toggle()
                                
                            } label: {
                                if showStandard == true {
                                    Label("Hide Standard Events", systemImage: "calendar")
                                    
                                } else {
                                    Label("Show Standard Events", systemImage: "calendar")
                                    
                                }
                            }
                            //.disabled((showFavourite || showMuted) == false)
                            
                            Button {
                                showMuted.toggle()
                                
                            } label: {
                                if showMuted == true {
                                    Label("Hide Muted Events", systemImage: "bell.slash")
                                    
                                } else {
                                    Label("Show Muted Events", systemImage: "bell.slash")
                                    
                                }
                            }
                            //.disabled((showFavourite || showStandard) == false)
                            
                        } label: {
                            if !showStandard || !showMuted {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle.fill")

                            } else {
                                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")

                            }
                        }
                        .disabled(editMode .isEditing ? true : false)
                        
                    }
                }
            }
            .navigationBarTitle(dateToDisplay != nil ? formatStringForDate(date: dateToDisplay!) : "My Events")
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
