//
//  EventListView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-07-23.
//

import SwiftUI
import Foundation
import Combine

struct UniqueDate: Identifiable {
    let id: Date
    
}

struct EventListView: View {
    @EnvironmentObject var preferences: SettingsStore
    @EnvironmentObject var eventStore: EventStore
    
    @Binding var data: [Event]
    var dateToDisplay: Date?
    let saveAction: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    var isLightMode: Bool {
        colorScheme == .light
        
    }
    
    @State private var saveError: String? = nil
    
    @State private var editMode = EditMode.inactive
    
    @State private var showingSheet = false
    
    @State var showMuted = true
    @State var showStandard = true
    
    @State private var hasCachedEvents: Bool = false
    @State private var cachedEventsToShow: [EventOccurrence] = []
    
    @State private var eventsByDate: [Date: [EventOccurrence]] = [:]
    
    let maxDisplayedEvents = 50
    
    func titleBarText(displayDate: Date?) -> String {
        var titleText: String = ""
        
        if displayDate == nil {
            titleText = NSLocalizedString("My Events", comment: "")
            
            return titleText
            
        } else {
            titleText = displayDate != nil ? displayDate!.formattedDate(.long) : "My Events"
            
            return titleText
            
        }
    }
    
    @State private var timeUpdater: String = ""
    
    @State private var timer: Timer?
    @State private var timerValue: Int = 0
    
    func showNewEventSheetView() {
        showingSheet = true
        
    }
    
    //@State private var isLoading: Bool = false  // Optional, for handling loading state
    private func invalidateCache() {
        cachedEventsToShow = []
        hasCachedEvents = false
        
    }
    
    private func cacheEvents() {
        print("Caching events")
        
        var agreeingEvents: [EventOccurrence] = []
        
        if let date = dateToDisplay {
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let hideExpired = preferences.removePassedEvents && !preferences.keepEventHistory
            
            agreeingEvents = data.occurrences(overlapping: DateInterval(start: dayStart, end: dayEnd), hideExpired: hideExpired)
            
        } else {
            var goodEvents: [EventOccurrence] = []
            
            let displayedData = data.map { $0.displayOccurrence() }
            
            let filteredData = preferences.removePassedEvents == false ? displayedData : displayedData.filter { !$0.event.hasExpired() }
            
            goodEvents.append(contentsOf: filteredData.filter { $0.event.hasStarted && !$0.event.hasPassed })
            goodEvents.append(contentsOf: filteredData.filter { !$0.event.hasStarted && !$0.event.hasPassed })
            
            let pastEvents = filteredData
                .filter { $0.event.hasPassed }
                .sorted(by: { ($0.event.endDateAndTime ?? $0.event.dateAndTime) > ($1.event.endDateAndTime ?? $1.event.dateAndTime) })
            
            goodEvents.append(contentsOf: pastEvents)
            
            agreeingEvents = Array(goodEvents.prefix(maxDisplayedEvents))
            
        }
        
        cachedEventsToShow = agreeingEvents.sorted(by: { $0.event.dateAndTime < $1.event.dateAndTime })
        hasCachedEvents = true
        
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
    
    private func saveEvents() {
        Task {
            do {
                try await eventStore.save(events: data)
                
            } catch {
                saveError = error.localizedDescription
                
            }
        }
    }
    
    var eventsToShow: [EventOccurrence] {
        return cachedEventsToShow
        
    }
    
    private func rebuildEventsByDate() {
        var grouped: [Date: [EventOccurrence]] = [:]
        
        let calendar = Calendar.current
        
        for occurrence in eventsToShow {
            let event = occurrence.event
            
            guard (showMuted || !event.isMuted), (showStandard || !event.isStandard) else {
                continue
                
            }
            
            var relevantDates: [Date] = []
            
            if let dateToDisplay {
                if event.isOnDates.contains(where: { $0.isSameDay(as: dateToDisplay) }) {
                    relevantDates.append(calendar.startOfDay(for: event.isOnDates.filter({ $0.isSameDay(as: dateToDisplay) }).first ?? event.dateAndTime))
                    
                }
                
            } else {
                relevantDates.append(calendar.startOfDay(for: event.dateAndTime))
                
            }
            
            for day in relevantDates {
                grouped[day, default: []].append(occurrence)
                
            }
        }
        
        eventsByDate = grouped
        
    }
    
    var uniqueDates: [UniqueDate] {
        var datesSeen: [UniqueDate] = []
        
        for occurrence in eventsToShow {
            let event = occurrence.event
            
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
                
                // If dateAndTime is not unique or doesn't match then check event.isOnDates for given day
                if dateToAdd == nil && dateToDisplay != nil {
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
    
    var listDisplay: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let pinnedEvents = eventsToShow.filter { $0.event.isPinned }
                
                if !pinnedEvents.isEmpty && dateToDisplay == nil {
                    Text("Pinned")
                        .font(.title3)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    ForEach(pinnedEvents) { pinnedEvent in
                        EventTileView(for: pinnedEvent)
                            .id("pinned-\(pinnedEvent.id)")
                        
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                }
                
                ForEach(uniqueDates) { uniqueDate in
                    // Date header for when used with multiple dates
                    if dateToDisplay == nil {
                        Text(uniqueDate.id.formattedDate(.long))
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        
                    }
                    
                    let normalizedDate = Calendar.current.startOfDay(for: uniqueDate.id)
                    let eventsForDate = eventsByDate[normalizedDate] ?? []
                    
                    ForEach(eventsForDate) { occurrence in
                        EventTileView(for: occurrence)
                        
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
//                        NoEventsView(singleDayDisplay: dateToDisplay != nil ? true : false)
                        ContentUnavailableView(
                            "No Events Saved",
                            systemImage: "nosign.badge.clock",
                            description: Text("Tap below to add a new event")
                            
                        )
                        //listDisplay
                        
                    } else {
                        ZStack{
                            if isLightMode && preferences.showFilmGrain {
                                NoiseView()
                                
                            }
                            
                            listDisplay
                            
                        }
                    }
                }
                .toolbar {
                    if !eventsToShow.isEmpty {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    showStandard.toggle()
                                    
                                } label: {
                                    if showStandard {
                                        Label("Hide Standard Events", systemImage: "diamond")
                                        
                                    } else {
                                        Label("Show Standard Events", systemImage: "diamond.fill")
                                        
                                    }
                                }
                                //.disabled(!canHideStandard)
                                
                                Button {
                                    showMuted.toggle()
                                    
                                } label: {
                                    if showMuted {
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
                        saveEvents()
                        
                    }
                }
                // Clear cache and rebuild event list on change of list
                .onChange(of: data) { oldValue, newValue in
                    invalidateCache()
                    cacheEvents()
                    rebuildEventsByDate()
                    
                }
                // Rebuild list when filters change
                .onChange(of: showMuted) { oldValue, newValue in
                    rebuildEventsByDate()
                    
                }
                .onChange(of: showStandard) { oldValue, newValue in
                    rebuildEventsByDate()
                    
                }
                // Initial build of event list
                .onAppear {
                    invalidateCache()
                    DispatchQueue.main.async {
                        cacheEvents()
                        rebuildEventsByDate()
                        
                    }
                }
                .alert("Failed to Save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                    Button("OK", role: .cancel) {}
                    
                } message: {
                    Text(saveError ?? "")
                    
                }
            }
        }
    }
}

struct EventListView_Previews: PreviewProvider {
    static var previews: some View {
        let previewPreferences = SettingsStore()
        let previewData = EventData()
        
        //previewPreferences.listTinting = true
        
        let calendar = Calendar.current
        
        let dateToDisplay: Date? = nil
        
        previewData.events = [
            Event(name: "Sample Event 1", emoji: "🌲", dateAndTime: Date(), endDateAndTime: calendar.date(byAdding: .minute, value: 30, to: Date())),
            Event(name: "Sample Event 2", dateAndTime: calendar.date(byAdding: .minute, value: 50, to: Date())!, endDateAndTime: calendar.date(byAdding: .minute, value: 100, to: Date()), isMuted: true),
            Event(name: "Sample Event 3", emoji: "🩻", dateAndTime: calendar.date(byAdding: .minute, value: 150, to: Date())!, endDateAndTime: calendar.date(byAdding: .minute, value: 200, to: Date()), isFavourite: true),
            Event(name: "Sample Event 4", emoji: "⚽️", dateAndTime: calendar.date(byAdding: .day, value: 5, to: Date())!, endDateAndTime: calendar.date(byAdding: .day, value: 5, to: Date())),
            Event(name: "Sample Event 5", emoji: "💛", dateAndTime: calendar.date(byAdding: .month, value: 1, to: Date())!, endDateAndTime: calendar.date(byAdding: .month, value: 1, to: Date()), isFavourite: true),
            Event(name: "Sample Event 6", emoji: "💜", dateAndTime: calendar.date(byAdding: .month, value: 1, to: Date())!, endDateAndTime: calendar.date(byAdding: .month, value: 1, to: Date()), isMuted: true)
                  
            // Add more sample events as needed
                  
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        let previewStore = EventStore()
        previewStore.events = previewData.events
        
        //return EventListView(data: previewEvents, saveAction: {})
        return EventListView(data: previewEvents, dateToDisplay: dateToDisplay, saveAction: {})
            .environmentObject(previewPreferences)
            .environmentObject(previewStore)
        
    }
}

