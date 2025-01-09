//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation
import Combine

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
    
    @State private var displayText = NSLocalizedString("Loading...", comment: "")
    
    private func startOneTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            displayText = NSLocalizedString("No Saved Events", comment: "")
            
        }
    }
    
    var body: some View {
        VStack {
            if singleDayDisplay {
                Text("No Events")
                    .font(.title2)
                    .bold()
                
            } else {
                Text(displayText)
                    .font(.title2)
                    .bold()
                
            }
        }
            .onAppear {
                startOneTimeTimer()
                
            }
    }
}

struct EventListView: View {
    @StateObject var preferences = SettingsStore()
    
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
    
    let maxDisplayedEvents = 50
    
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
    //@State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    @State private var timer: Timer?
    @State private var timerValue: Int = 0
    
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
        //print("compareDates")
        
        for _ in cachedEventsToShow {
            //print(event.name!)
            
        }
        
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
        var dateString: String = ""
        
        //let oneDayInSeconds: Double = 60 * 60 * 24
        let oneWeekInSeconds: Double = 60 * 60 * 24 * 7
        
        if abs(date.timeIntervalSinceNow) < oneWeekInSeconds {
            if Calendar.current.isDate(date, inSameDayAs: Date()) {
                dateString = NSLocalizedString("Today", comment: "")
                
            } else if Calendar.current.isDateInYesterday(date) {
                dateString = NSLocalizedString("Yesterday", comment: "")
                
            } else if Calendar.current.isDateInTomorrow(date) {
                dateString = NSLocalizedString("Tomorrow", comment: "")
                
            } else {
                dateFormatter.dateFormat = "EEEE"
                let dayString = dateFormatter.string(from: date)
                
                if date.timeIntervalSinceNow > 0.0 {
                    //let stringFormat = NSLocalizedString("Next %@", comment: "")
                    //dateString = String(format: stringFormat, dayString)
                    dateString = dayString
                    
                } else {
                    let stringFormat = NSLocalizedString("Last %@", comment: "")
                    dateString = String(format: stringFormat, dayString)
                    
                }
            }
            
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year) {
            dateFormatter.dateFormat = "MMMM d"
            
            let dayString = dateFormatter.string(from: date)
            dateString = "\(dayString)"
            
        } else {
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
            
            dateString = dateFormatter.string(from: date)
        }
        
        return dateString
        
    }
    
    @State private var hasCachedEvents: Bool = false
    @State private var cachedEventsToShow: [Event] = []
    
    //@State private var isLoading: Bool = false  // Optional, for handling loading state
    
    private func cacheEvents() {
        print("Caching eventss")
        //guard cachedEventsToShow.count == 0 else { return } // Exit if already cached
        
        //        if !cachedEventsToShow.isEmpty {
        //            print("Cached events already exist. Not caching again.")
        //
        //            return
        //
        //        }
        
        print("recaching events")
        
        //isLoading = true // Optional, show loading state
        
        /*
         // Collect future events that have started but not passed
         var displayableEvents = data.filter { $0.hasStarted && !$0.hasPassed }
         
         // If space remains, add upcoming events that haven't started
         if displayableEvents.count < maxDisplayedEvents {
         let futureOnlyEvents = data.filter { !$0.hasStarted && !displayableEvents.contains(where: { $0.id == $0.id }) }
         displayableEvents.append(contentsOf: futureOnlyEvents)
         
         }
         
         // If space still remains, add past events, sorted by descending end date
         // Newer events added first
         if displayableEvents.count < maxDisplayedEvents {
         let pastEvents = data
         .filter { $0.hasPassed && !displayableEvents.contains(where: { $0.id == $0.id }) }
         .sorted(by: { ($0.endDateAndTime ?? $0.dateAndTime) > ($1.endDateAndTime ?? $1.dateAndTime) })
         displayableEvents.append(contentsOf: pastEvents)
         
         }
         
         // If a specific date is set, allow any events on that date.
         var agreeingEvents: [Event] = []
         if let targetDate = dateToDisplay {
         print("wer here")
         
         for possibleEvent in displayableEvents {
         if Calendar.current.isDate(possibleEvent.dateAndTime, inSameDayAs: targetDate) {
         displayableEvents.append(possibleEvent)
         
         }
         }
         
         agreeingEvents = displayableEvents.filter { shouldDisplay(event: $0, dateToDisplay: dateToDisplay) }
         
         } else {
         // Otherwise, filter based on `shouldDisplay` logic
         print("should display from cache:")
         agreeingEvents = displayableEvents.filter { shouldDisplay(event: $0, dateToDisplay: dateToDisplay) }
         
         }
         
         // Limit future events to max displayed events
         if displayableEvents.count > maxDisplayedEvents {
         displayableEvents = Array(displayableEvents.prefix(maxDisplayedEvents))
         
         }
         
         DispatchQueue.main.async {
         self.cachedEventsToShow = agreeingEvents.sorted(by: { $0.dateAndTime < $1.dateAndTime })
         self.hasCachedEvents = true
         //self.isLoading = false // Hide loading state
         
         }
         */
        
        var agreeingEvents: [Event] = []
        
        if let date = dateToDisplay {
            // Filter events occurring on the specified date
            agreeingEvents = data.filter { Calendar.current.isDate($0.dateAndTime, inSameDayAs: date) }
            
        }  else {
            var goodEvents: [Event] = []
            
            let filteredData = preferences.removePassedEvents == false ? data : data.filter { !$0.hasExpired() }
            
            // Add events that have started but not yet finished
            goodEvents.append(contentsOf: filteredData.filter { $0.hasStarted && !$0.hasPassed })
            
            // Add events that have not started or finished yet
            goodEvents.append(contentsOf: filteredData.filter { !$0.hasStarted && !$0.hasPassed })
            
            // Add past events in reverse chronological order
            let pastEvents = filteredData.filter { $0.hasPassed }.sorted(by: { $0.endDateAndTime! > $1.endDateAndTime! })
            goodEvents.append(contentsOf: pastEvents)
            
            // Limit to `eventsToShow` count
            agreeingEvents = Array(goodEvents.prefix(maxDisplayedEvents))
            
        }
        
        
        // Dispatch updates on the main queue
        DispatchQueue.main.async {
            self.cachedEventsToShow = agreeingEvents.sorted(by: { $0.dateAndTime < $1.dateAndTime })
            self.hasCachedEvents = true
        }
    
    }
    
    var eventsToShow: [Event] {
        if cachedEventsToShow.isEmpty {
            cacheEvents()
            
        }
        
        return cachedEventsToShow
        
    }
    /*
    var eventsToShow: [Event] {
        var agreeingEvents: [Event] = []

        if hasCachedEvents == false {
            print("eventsToShow")
            
            // Collect future events that have started but not passed
            var futureEvents = data.filter { $0.hasStarted && !$0.hasPassed }
            
            // Limit future events to max displayed events
            if futureEvents.count > maxDisplayedEvents {
                futureEvents = Array(futureEvents.prefix(maxDisplayedEvents))
            }
            
            // If space remains, add upcoming events that haven't started
            if futureEvents.count < maxDisplayedEvents {
                let remainingSlots = maxDisplayedEvents - futureEvents.count
                let futureOnlyEvents = data.filter { !$0.hasStarted && !futureEvents.contains(where: { $0.id == $0.id }) }
                futureEvents.append(contentsOf: futureOnlyEvents.prefix(remainingSlots))
            }
            
            // If space still remains, add past events, sorted by descending end date
            if futureEvents.count < maxDisplayedEvents {
                let remainingSlots = maxDisplayedEvents - futureEvents.count
                let pastEvents = data
                    .filter { $0.hasPassed && !futureEvents.contains(where: { $0.id == $0.id }) }
                    .sorted(by: { ($0.endDateAndTime ?? $0.dateAndTime) > ($1.endDateAndTime ?? $1.dateAndTime) })
                futureEvents.append(contentsOf: pastEvents.prefix(remainingSlots))
            }
            
            // If a specific date is set, filter events occurring on that date
            if let targetDate = dateToDisplay {
                agreeingEvents = data.prefix(maxDisplayedEvents).filter { event in
                    event.isOnDates.contains { Calendar.current.isDate($0, equalTo: targetDate, toGranularity: .day) }
                }
            } else {
                // Otherwise, filter based on `shouldDisplay` logic
                agreeingEvents = futureEvents.filter { shouldDisplay(event: $0, dateToDisplay: dateToDisplay) }
            }
            
            // Return events sorted by `dateAndTime`
            
        }
        
        cachedEventsToShow = agreeingEvents.sorted(by: { $0.dateAndTime < $1.dateAndTime })
        
        hasCachedEvents = true
        
        return cachedEventsToShow
        
    }
     */
    
    var uniqueDates: [UniqueDate] {
        //print("using uniqueDates precache")
        
        if cachedEventsToShow.isEmpty {
            cacheEvents()
            print("caching events")
            
        }
        
        //print(cachedEventsToShow)
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
    /*
    func countEvents(withType type: EventType, in events: [Event]) -> Int {
        print("countEvents")
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
        let noMutedOrStandard = countEvents(withType: .isMuted, in: eventsToShow) == 0 && (!showFavourite || countEvents(withType: .isStandard, in: eventsToShow) == 0)
        let noFavouriteEvents = countEvents(withType: .isFavourite, in: eventsToShow) == 0
        
        return !(noMutedOrStandard || noFavouriteEvents)
    }
    
    var canHideMuted: Bool {
        let noFavouritesOrStandard = countEvents(withType: .isFavourite, in: eventsToShow) == 0 && (!showMuted || countEvents(withType: .isStandard, in: eventsToShow) == 0)
        let noMutedEvents = countEvents(withType: .isMuted, in: eventsToShow) == 0
        
        return !(noFavouritesOrStandard || noMutedEvents)
        
    }
     */
    
    func shouldDisplay(event: Event, dateToDisplay: Date?) -> Bool {
        print("shouldDisplay")
        if dateToDisplay == nil {
            if preferences.removePassedEvents == false {
                return true
                
            } else if preferences.removePassedEvents == true {
                if event.hasExpired() == false {
                    return true
                    
                } else if event.hasExpired() == true {
                    return false
                    
                }
            }
            
        } else {
            for occuringDate in event.isOnDates {
                if Calendar.current.isDate(occuringDate, equalTo: dateToDisplay!, toGranularity: .day) {
                    return true
                    
                }
            }
        }
        
        return false
        
    }
    
    func eventTile(event: Event) -> some View {
        ZStack {
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
                            .onChange(of: timer) { _ in
                                // Reset timeUpdater every second
                                // This tricks the text object into getting a new timeUntil
                                timeUpdater = " "
                                timeUpdater = ""
                                
                            }
                            .foregroundStyle(event.hasPassed ? .red : .primary)
                            .bold(event.hasStarted)
                        
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
    }
    
    func listSection(for section: UniqueDate) -> some View {
        ForEach($data) { $event in
            // Check if the event should be displayed based on its conditions
            let isInEventsToShow = eventsToShow.contains { $0.id == event.id }
            //let dataIndex = data.firstIndex(where: { $0.id == event.id })

            // Ensure the event is valid and conditions are met
            if isInEventsToShow,
               //let index = dataIndex,
               Calendar.current.isDate(event.dateAndTime, equalTo: dateToDisplay ?? section.id, toGranularity: .day),
               (dateToDisplay != nil || Calendar.current.isDate(event.dateAndTime, inSameDayAs: section.id)),
               (showFavourite || !event.isFavourite),
               (showMuted || !event.isMuted),
               (showStandard || !event.isStandard) {

                NavigationLink(destination: EventDetailView(data: $data, eventID: event.id)) {
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
                                            
                                            print("Toggling favourite on \(event.name!)")
                                            
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
                                            
                                            print("Deleting \($event.name)")
                                            
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
                                                
                                                print("Toggling mute on \(event.name!)")
                                                
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
                            .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.6, brightness: 1.2, opacity: 0.25) : Color(UIColor.systemGray6))
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
                                
                                Divider()
                                
                                NavigationLink(
                                    destination: EventDetailView(data: $data, eventID: data[$data.firstIndex(where: { $0.id == event.id }) ?? 0].id, showEditEventSheet: true),
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
        .onDelete { indexSet in            
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
        .background(.background)
        .scrollContentBackground(.hidden)
        .listRowSpacing(5)
        
        .onAppear {
            cacheEvents()
            startTimer()
            print("HERE START")
            
        }
        
        .onDisappear {
            stopTimer()
            print("HERE STOP")
            
        }
        .onChange(of: data.count) { _ in
            print("updated length")
            cacheEvents()
            
        }
        
    }
    
    var body: some View {
        VStack {
            NavigationStack {
                VStack {
                    if eventsToShow.isEmpty {
                        NoEventsView(singleDayDisplay: dateToDisplay != nil ? true : false)
                        //listDisplay
                        
                    } else {
                        listDisplay
                        
                    }
                }
                .toolbar {
                    if !eventsToShow.isEmpty {
                        /*
                         ToolbarItem(placement: .navigationBarLeading) {
                         Button("Test Performance") {
                         for index in 1 ... 100 {
                         let newTestEvent = Event(name: "Test Event \(index)")
                         
                         data.append(newTestEvent)
                         data.sort(by: { $0.dateAndTime < $1.dateAndTime })
                         
                         }
                         
                         Task {
                         do {
                         try await EventStore().save(events: data)
                         
                         } catch {
                         fatalError(error.localizedDescription)
                         
                         }
                         }
                         }
                         }
                         */
                        
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
                                //.disabled(!canHideStandard)
                                
                                Button {
                                    showMuted.toggle()
                                    
                                } label: {
                                    if showMuted == true {
                                        Label("Hide Muted Events", systemImage: "bell.slash")
                                        
                                    } else {
                                        Label("Show Muted Events", systemImage: "bell.slash.fill")
                                        
                                    }
                                }
                                //.disabled(!canHideMuted)
                                
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
                .navigationBarTitleDisplayMode(.large)
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
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            timerValue += 1
            
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        
    }
        
    private func resetTimer() {
        timerValue = 0
        
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        let calendar = Calendar.current
        
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date(), endDateAndTime: calendar.date(byAdding: .minute, value: 30, to: Date())),
            Event(name: "Sample Event 2", isMuted: true),
            Event(name: "Sample Event 3", isFavourite: true)
            // Add more sample events if needed
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        
        return EventListView(data: previewEvents, saveAction: {})
        
    }
}
