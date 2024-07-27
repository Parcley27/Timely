//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation

enum EventType {
    case isFavourite
    case isStandard
    case isMuted
    
}

struct UniqueDate: Identifiable {
    let id: Date
    
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
    
    func titleBarText(displayDate: Date?) -> String {
        var titleText: String = ""
        
        if displayDate == nil {
            titleText = NSLocalizedString("My Events", comment: "")
            return titleText
            
        } else {
            titleText = formatStringForDate(date: displayDate!, style: "long")
            return titleText
            
        }
    }
    
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
    
    func formatStringForDate(date: Date, style: String?) -> String {
        let dateFormatter = DateFormatter()
        
        if style == "short" {
            dateFormatter.dateStyle = .short
            
        } else if style == "long" {
            dateFormatter.dateStyle = .long
            
        } else if style == "full" {
            dateFormatter.dateStyle = .full
            
        } else {
            dateFormatter.dateStyle = .medium
            
        }
        
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
            if (showMuted || !event.isMuted) && (showStandard || !event.isStandard) {
                var isUnique = true
                
                for seenDate in datesSeen {
                    if compareDates(event: event, date: seenDate.id) {
                        isUnique = false
                        break
                        
                    }
                }
                
                if isUnique {
                    datesSeen.append(UniqueDate(id: event.dateAndTime))
                    
                }
            }
        }
        
        return datesSeen
        
    }
    
    func countEvents(withType type: EventType, in events: [Event]) -> Int {
        switch type {
        case .isFavourite:
            return events.filter { $0.isFavourite }.count
            
        case .isStandard:
            return events.filter { $0.isStandard }.count
            
        case .isMuted:
            return events.filter { $0.isMuted }.count
            
        }
    }
    
    var canHideStandard: Bool {
        if ((countEvents(withType: .isFavourite, in: eventsToShow) == 0 && (!showMuted || countEvents(withType: .isMuted, in: eventsToShow) == 0)) || countEvents(withType: .isStandard, in: eventsToShow) == 0) {
            return false
            
        } else {
            return true
            
        }
    }
    
    var canHideMuted: Bool {
        if ((countEvents(withType: .isFavourite, in: eventsToShow) == 0 && (!showMuted || countEvents(withType: .isStandard, in: eventsToShow) == 0 )) || countEvents(withType: .isMuted, in: eventsToShow) == 0 ) {
            return false
            
        } else {
            return true
            
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
            
            if shouldDisplay(event: event, dateToDisplay: dateToDisplay) && shouldDisplay(event: event, dateToDisplay: section.id) {
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
                    .contextMenu {
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
                        } label: {
                            if event.isFavourite {
                                Label("Unfavourite", systemImage: "star.slash")
                                
                            } else {
                                Label("Favourite", systemImage: "star")
                                
                            }
                        }
                        
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
                        } label: {
                            if event.isMuted {
                                Label("Unmute", systemImage: "bell")
                                
                            } else {
                                Label("Mute", systemImage: "bell.slash")
                                
                            }
                        }
                        
                        NavigationLink(
                            destination: EventDetailView(data: $data, event: 0, showEditEventSheet: true),
                            label: {
                                Label("Edit", systemImage: "slider.horizontal.3")
                            })
                        
                        Divider()
                        
                        Button {
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
                        } label: {
                            Label("Delete \"\(event.name!)\"", systemImage: "trash")
                            
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
    
    var listDisplay: some View {
        List {
            ForEach(uniqueDates) { UniqueDate in
                if dateToDisplay == nil {
                    Section(dateToDisplay == nil ? formatStringForDate(date: UniqueDate.id, style: "long") : "") {
                        listSection(for: UniqueDate)
                        
                    }
                    
                } else {
                    listSection(for: UniqueDate)
                    
                }
            }
        }
        .listRowSpacing(5)
        
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
                            Button {
                                showStandard.toggle()
                                
                            } label: {
                                if showStandard == true {
                                    Label("Hide Standard Events", systemImage: "diamond")
                                    
                                } else {
                                    Label("Show Standard Events", systemImage: "diamond.fill")
                                    
                                }
                            }
                            .disabled(!canHideStandard)
                            
                            Button {
                                showMuted.toggle()
                                
                            } label: {
                                if showMuted == true {
                                    Label("Hide Muted Events", systemImage: "bell.slash")
                                    
                                } else {
                                    Label("Show Muted Events", systemImage: "bell.slash.fill")
                                    
                                }
                            }
                            .disabled(!canHideMuted)
                            
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
            .navigationBarTitle(titleBarText(displayDate: dateToDisplay))
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
