//
//  TimelyApp.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//


import SwiftUI

@main
struct TimelyApp: App {
    @StateObject var eventStore = EventStore()
    
    let versionNumber = "3.1.0"
    let buildNumber = "20"
    
    func filterPassedEvents(events: [Event]) -> [Event]? {
        var passedEvents = events.filter { $0.hasPassed == true }
        passedEvents = passedEvents.filter { $0.isMuted == false }
        
        if SettingsStore().removePassedEvents {
            passedEvents = passedEvents.filter { $0.hasExpired() == false }
            
        }
        
        if SettingsStore().showBadge {
            return passedEvents
            
        } else {
            return []
            
        }
    }
    
    func localizedNumber(_ number: Int) -> Int {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return Int(formatter.string(from: NSNumber(value: number))!) ?? number
        
    }
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    //@State var selectedTab: Int = 0
    @State var lastTab: Int = 0
    
    @State private var showNewSheet: Bool = false
    
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    
    var plusButton: some View {
        ZStack {
            Circle()
                .stroke(.blue, lineWidth: 7.5)
                .frame(width: 100)
                .background(.bar, in: Circle())
            
            Circle()
                .stroke(.background, lineWidth: 7.5)
                .frame(width: 100)
                .opacity(0.5)
            
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
                    //TabView(selection: $selectedTab) {
                    TabView() {
                        EventListView(data: $eventStore.events) {
                            Task {
                                do {
                                    try await eventStore.save(events: eventStore.events)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                        }
                        .task {
                            do {
                                //try await eventList.load()
                                eventStore.loadFromiCloud()
                                
                                print("Loading events: ")
                                
                                for event in eventStore.events {
                                    print(event.name!, terminator: " ")
                                    
                                }
                                
                                print("")
                                
                            }
                        }
                        .badge(localizedNumber(filterPassedEvents(events: eventStore.events)!.count))
                        .tabItem {
                            Label("My Events", systemImage: "list.bullet")
                            
                        }
                        //.tag(0)
                        
                        EventListView(data: $eventStore.events) {
                            Task {
                                do {
                                    try await eventStore.save(events: eventStore.events)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                        }
                        .task {
                            do {
                                //try await eventList.load()
                                eventStore.loadFromiCloud()
                                
                                print("Loading events: ")
                                
                                for event in eventStore.events {
                                    print(event.name!, terminator: " ")
                                    
                                }
                                
                                print("")
                                
                            }
                        }
                        //.tag(1)
                            
                        CalendarView(data: $eventStore.events, month: currentMonth, year: currentYear) {
                            Task {
                                do {
                                    try await eventStore.save(events: eventStore.events)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                        }
                        .task {
                            do {
                                //try await eventList.load()
                                eventStore.loadFromiCloud()
                                
                                print("Loading events: ")
                                
                                for event in eventStore.events {
                                    print(event.name!, terminator: " ")
                                    
                                }
                                
                                print("")
                                
                            }
                        }
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                            
                        }
                        //.tag(2)
                        
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
                        NewEventSheetView(data: $eventStore.events)
                        
                    }
                }
            }
            .onReceive(timer) { _ in
                if SettingsStore().removePassedEvents && SettingsStore().keepEventHistory == false {
                    eventStore.deleteExpiredEvents()
                    
                }
            }
        }
    }
}
