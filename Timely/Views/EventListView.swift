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
    
    @State private var editMode = EditMode.inactive
    
    @State private var showingSheet = false
    
    @State var showMuted = true
    @State var showStandard = true
    
    @State private var hasCachedEvents: Bool = false
    @State private var cachedEventsToShow: [Event] = []
    
    @State private var eventsByDate: [Date: [Event]] = [:]
    
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
        
        var agreeingEvents: [Event] = []
        
        if let date = dateToDisplay {
            agreeingEvents = data.filter { $0.dateAndTime.isSameDay(as: date) }
            
            for event in data {
                if event.isOnDates.contains(where: { $0.isSameDay(as: date) }) {
                    agreeingEvents.append(event)
                    
                }
            }
            
        } else {
            var goodEvents: [Event] = []
            
            let filteredData = preferences.removePassedEvents == false ? data : data.filter { !$0.hasExpired() }
            
            goodEvents.append(contentsOf: filteredData.filter { $0.hasStarted && !$0.hasPassed })
            goodEvents.append(contentsOf: filteredData.filter { !$0.hasStarted && !$0.hasPassed })
            
            let pastEvents = filteredData
                .filter { $0.hasPassed }
                .sorted(by: { ($0.endDateAndTime ?? .distantPast) > ($1.endDateAndTime ?? .distantPast) })
            
            goodEvents.append(contentsOf: pastEvents)
            
            agreeingEvents = Array(goodEvents.prefix(maxDisplayedEvents))
            
        }
        
        cachedEventsToShow = agreeingEvents.sorted(by: { $0.dateAndTime < $1.dateAndTime })
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
                // TODO: Present error to user instead of crashing
                print("Failed to save events: \(error.localizedDescription)")
                
            }
        }
    }
    
    var eventsToShow: [Event] {
        return cachedEventsToShow
        
    }
    
    private func rebuildEventsByDate() {
        var grouped: [Date: [Event]] = [:]
        
        for event in eventsToShow {
            guard (showMuted || !event.isMuted),
                  (showStandard || !event.isStandard) else {
                continue
                
            }
            
            var relevantDates: [Date] = []
            
            if dateToDisplay == nil || event.dateAndTime.isSameDay(as: dateToDisplay!) {
                relevantDates.append(event.dateAndTime)
                
            }
            
            if let dateToDisplay = dateToDisplay {
                for recurringDate in event.isOnDates {
                    if recurringDate.isSameDay(as: dateToDisplay) {
                        relevantDates.append(recurringDate)
                        
                    }
                }
                
            } else {
                relevantDates = [event.dateAndTime]
                
            }
            
            for date in relevantDates {
                let normalizedDate = Calendar.current.startOfDay(for: date)
                
                if grouped[normalizedDate] == nil {
                    grouped[normalizedDate] = []
                    
                }
                
                grouped[normalizedDate]?.append(event)
                
            }
        }
        
        eventsByDate = grouped
        
    }
    
    var uniqueDates: [UniqueDate] {
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
    
    var listDisplay: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let pinnedEvents = eventsToShow.filter { $0.isPinned ?? false }
                
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
                    
                    ForEach(eventsForDate) { event in
                        EventTileView(for: event)
                        
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
                            if isLightMode {
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

