//
//  TimelyApp.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//

// Change color with system theme
//
//@Environment(\.colorScheme) var colorScheme
//
//.foregroundColor(colorScheme == .dark ? .white : .black)

import SwiftUI

@main
struct TimelyApp: App {
    @StateObject private var eventList = EventStore()
    
    func filterPassedEvents(events: [Event]) -> [Event] {
        let passedEvents = events.filter { $0.hasPassed == true }
        
        return passedEvents
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                EventListView(data: $eventList.events) {
                    Task {
                        do {
                            try await eventList.save(events: eventList.events)
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                }
                .badge(filterPassedEvents(events: eventList.events).count)
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                
                    .task {
                        do {
                            try await eventList.load()
                            print("Loading events: \(eventList.events)")
                        } catch {
                            fatalError(error.localizedDescription)
                        }
                    }
                
                //Spacer()
                // Use spacer to give room for large add button later
                
                //Settings(data: $eventList.events)
                CalendarView(data: $eventList.events)
                    //.badge()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
        }
    }
}
