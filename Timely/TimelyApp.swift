//
//  TimelyApp.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//

import SwiftUI

@main
struct TimelyApp: App {
    @StateObject private var eventList = EventStore()
    
    func filterPassedEvents(events: [Event]) -> [Event] {
        let passedEvents = events.filter { $0.hasPassed == true }
        
        return passedEvents
    }
    
    @State var selectedTab: Int = 0
    @State var lastTab: Int = 0

    @State private var showNewSheet: Bool = false
    
    var plusButton: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: 5)
                .frame(width: 100)
                .background(
                      .bar,
                      in: Circle()
                   )

            Image(systemName: "plus")
                .resizable()
                .frame(width: 50.0, height: 50.0)
                .foregroundStyle(.secondary)
            
        }
    }

    var body: some Scene {
        WindowGroup {
            VStack {
                ZStack {
                    TabView(selection: $selectedTab) {
                        Group {
                            EventListView(data: $eventList.events) {
                                Task {
                                    do {
                                        try await eventList.save(events: eventList.events)
                                    } catch {
                                        fatalError(error.localizedDescription)
                                    }
                                }
                            }
                            .task {
                                do {
                                    try await eventList.load()
                                    print("Loading events: \(eventList.events)")
                                } catch {
                                    fatalError(error.localizedDescription)
                                }
                            }
                            .badge(filterPassedEvents(events: eventList.events).count)
                            .tabItem {
                                Label("Events", systemImage: "list.bullet")
                            }
                            .tag(0)
                            
                            if lastTab == 0 {
                                EventListView(data: $eventList.events) {
                                    Task {
                                        do {
                                            try await eventList.save(events: eventList.events)
                                        } catch {
                                            fatalError(error.localizedDescription)
                                        }
                                    }
                                }
                                .tag(1)
                            } else if lastTab == 2 {
                                CalendarView(data: $eventList.events) {
                                    Task {
                                        do {
                                            try await eventList.save(events: eventList.events)
                                        } catch {
                                            fatalError(error.localizedDescription)
                                        }
                                    }
                                }
                                .tag(1)
                            }
                            
                            CalendarView(data: $eventList.events) {
                                Task {
                                    do {
                                        try await eventList.save(events: eventList.events)
                                    } catch {
                                        fatalError(error.localizedDescription)
                                    }
                                }
                            }
                            .task {
                                do {
                                    try await eventList.load()
                                    print("Loading events: \(eventList.events)")
                                } catch {
                                    fatalError(error.localizedDescription)
                                }
                            }
                            .tabItem {
                                Label("Calendar", systemImage: "calendar")
                            }
                            .tag(2)
                        }
                    }
                    .onChange(of: selectedTab) { newTab in
                        if newTab == 0 || newTab == 2 {
                            lastTab = selectedTab
                            print(selectedTab)
                        }
                        
                        if newTab == 1 {
                            print(lastTab)
                            selectedTab = lastTab
                            print("Switching tab")
                            print(selectedTab)
                        }
                    }
                    
                    GeometryReader { metrics in
                        plusButton
                            .frame(width: metrics.size.width / 4.5, height: metrics.size.height / 9.0)
                            .onTapGesture {
                                print("plus")
                                showNewSheet = true
                            }
                            .position(x: metrics.size.width * 0.5, y: metrics.size.height - 48)
                    }
                    .sheet(isPresented: $showNewSheet) {
                        NewEventSheetView(data: $eventList.events)
                    }
                }
            }
        }
    }
}
