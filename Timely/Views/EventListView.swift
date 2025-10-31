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
    @EnvironmentObject var preferences: SettingsStore
    @EnvironmentObject var eventStore: EventStore
    
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
    //@State var showFavourite = true
    
    @State private var newTimeUntilEvent: String = ""
    
    let maxDisplayedEvents = 50
    
    func titleBarText(displayDate: Date?) -> String {
        var titleText: String = ""
        
        if displayDate == nil {
            titleText = NSLocalizedString("My Events", comment: "")
            return titleText
            
        } else {
            titleText = displayDate!.formattedDate(.long)
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
        
        var agreeingEvents: [Event] = []
        
        if let date = dateToDisplay {
            // Filter events occurring on the specified date
            agreeingEvents = data.filter { $0.dateAndTime.isSameDay(as: date) }
            
            for event in data {
                if event.isOnDates.contains(where: { $0.isSameDay(as: date) }) {
                    agreeingEvents.append(event)
                    
                }
            }
            
            
        } else {
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
                // Ensure any added date matches dateToDisplay if not nil
                let shouldAddDate: (Date) -> Bool = { date in
                    guard let dateToDisplay = dateToDisplay else { return true }
                    return date.isSameDay(as: dateToDisplay)
                    
                }
                
                var dateToAdd: Date?
                
                // Check if event.dateAndTime is on a unique day and matches dateToDisplay
                if !datesSeen.contains(where: {
                    event.dateAndTime.isSameDay(as: $0.id)
                    
                }) && shouldAddDate(event.dateAndTime) {
                    dateToAdd = event.dateAndTime
                    
                }
                
                // If dateAndTime is not unique or doesn't match then check event.isOnDates
                if dateToAdd == nil {
                    for date in event.isOnDates {
                        if !datesSeen.contains(where: {
                            date.isSameDay(as: $0.id)
                        }) && shouldAddDate(date) {
                            dateToAdd = date
                            break
                            
                        }
                    }
                }
                
                // Add the resolved date if one was found
                if let uniqueDate = dateToAdd {
                    datesSeen.append(UniqueDate(id: uniqueDate))
                    
                }
            }
        }
        
        return datesSeen
        
    }
    
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
                if occuringDate.isSameDay(as: dateToDisplay!) {
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
                            .onChange(of: timer) {
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
            
            let isOnDate = event.isOnDates.contains { occuringDate in
                if occuringDate.isSameDay(as: dateToDisplay ?? section.id) {
                    
                    //print("\(event.name ?? "No name") not on provided date")

                    return true
                    
                }
                
                //print("\(event.name ?? "No name") not on provided date")
                
                return false
                
            }
            
            // Ensure the event is valid and conditions are met
            if isInEventsToShow,
               //let index = dataIndex,
               (event.dateAndTime.isSameDay(as: dateToDisplay ?? section.id) || (isOnDate && dateToDisplay != nil)),
               (dateToDisplay != nil || event.dateAndTime.isSameDay(as: section.id)),
               //(showFavourite || !event.isFavourite),
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
                                                        try await eventStore.save(events: data)
                                                        
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
                                                        try await eventStore.save(events: data)
                                                        
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
                                                            try await eventStore.save(events: data)
                                                            
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
                            .listRowBackground(preferences.listTinting ? event.averageColor(saturation: 0.6, brightness: 1.2, opacity: 0.25) : Color(UIColor.systemGray6))
                            .contextMenu {
                                Button {
                                    if let index = $data.firstIndex(where: { $0.id == event.id }) {
                                        data[index].isFavourite.toggle()
                                        Task {
                                            do {
                                                try await eventStore.save(events: data)
                                                
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
                                                try await eventStore.save(events: data)
                                                
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
                                                try await eventStore.save(events: data)
                                                
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
                    try await eventStore.save(events: data)
                    
                } catch {
                    fatalError(error.localizedDescription)
                    
                }
            }
            
        }
    }
    
    var listDisplay: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(uniqueDates) { uniqueDate in
                    if dateToDisplay == nil {
                        Text(uniqueDate.id.formattedDate(.long))
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                    }
                    
                    ForEach(data) { event in
                        let isInEventsToShow = eventsToShow.contains { $0.id == event.id }
                        
                        let isOnDate = event.isOnDates.contains { occuringDate in
                            occuringDate.isSameDay(as: dateToDisplay ?? uniqueDate.id)
                        }
                        
                        if isInEventsToShow,
                           (event.dateAndTime.isSameDay(as: dateToDisplay ?? uniqueDate.id) || (isOnDate && dateToDisplay != nil)),
                           (dateToDisplay != nil || event.dateAndTime.isSameDay(as: uniqueDate.id)),
                           (showMuted || !event.isMuted),
                           (showStandard || !event.isStandard) {
                            
                            NavigationLink(destination: EventDetailView(data: $data, eventID: event.id)) {
                                HStack(spacing: 12) {
                                    // Emoji icon
                                    Text(event.emoji ?? "📅")
                                        .font(.system(size: 36))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Event name
                                        Text(event.name ?? "Event Name")
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .lineLimit(2)
                                        
                                        // Time until
                                        Text(event.timeUntil)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Status badges (subtle pills)
                                    HStack(spacing: 6) {
                                        if event.isFavourite {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.yellow)
                                        }
                                        
                                        if event.isMuted {
                                            Image(systemName: "bell.slash.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                                .padding(16)
                                .background(
                                    ZStack {
                                        // Soft gradient background (derived from emoji/event)
                                        LinearGradient(
                                            colors: [
                                                event.averageColor(saturation: 0.3, brightness: 0.95, opacity: 1.0) ?? Color(.systemGray6),
                                                event.averageColor(saturation: 0.2, brightness: 0.95, opacity: 1.0) ?? Color(.systemGray5)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottomTrailing
                                        )
                                        
                                        // Noise texture overlay
                                        NoiseView()
                                            .opacity(0.08)
                                        
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    //event.averageColor(saturation: 0.3, brightness: 0.9, opacity: 1.0),
                                                    Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 0.5
                                            
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                //.glassEffect(in: .rect(cornerRadius: 24))
                                .glassEffect(.regular.tint(.white).interactive(), in: .rect(cornerRadius: 24.0))
                                
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            
                        }
                    }
                }
            }
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
                        ZStack{
                            NoiseView()
                            listDisplay
                        }
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
                                    Label("Filter", systemImage: "line.3.horizontal.decrease")
                                    
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
                .onChange(of: scenePhase) {
                    if scenePhase == .inactive {
                        Task {
                            do {
                                try await eventStore.save(events: data)
                                
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
        
        let dateToDisplay: Date? = nil
        
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date(), endDateAndTime: calendar.date(byAdding: .minute, value: 30, to: Date())),
            Event(name: "Sample Event 2", dateAndTime: calendar.date(byAdding: .minute, value: 50, to: Date())!, endDateAndTime: calendar.date(byAdding: .minute, value: 100, to: Date()), isMuted: true),
            Event(name: "Sample Event 3", dateAndTime: calendar.date(byAdding: .minute, value: 150, to: Date())!, endDateAndTime: calendar.date(byAdding: .minute, value: 200, to: Date()), isFavourite: true)
                  
            // Add more sample events as needed
                  
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        let previewStore = EventStore()
        previewStore.events = previewData.events
        
        //return EventListView(data: previewEvents, saveAction: {})
        return EventListView(data: previewEvents, dateToDisplay: dateToDisplay, saveAction: {})
            .environmentObject(SettingsStore())
            .environmentObject(previewStore)
        
    }
}

