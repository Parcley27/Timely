//
//  ContentView.swift
//  Timely
//
//  Created by Pierce Oxley on 12/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eventStore: EventStore
    
    @State var lastTab: Int = 0
    @State private var showNewSheet: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
    
    var body: some View {
        VStack {
            TabView {
                Tab("My Events", systemImage: "list.bullet") {
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
                            eventStore.loadFromiCloud()
                            
                            print("Loading events: ")
                            
                            for event in eventStore.events {
                                print(event.name!, terminator: " ")
                                
                            }
                            
                            print("")
                            
                        }
                    }
                    .badge(localizedNumber(filterPassedEvents(events: eventStore.events)!.count))
                    
                }
                
                Tab("Calendar", systemImage: "calendar") {
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
                            eventStore.loadFromiCloud()
                            
                            print("Loading events: ")
                            
                            for event in eventStore.events {
                                print(event.name!, terminator: " ")
                                
                            }
                            
                            print("")
                            
                        }
                    }
                }
                
                Tab("New Event", systemImage: "plus", role: .search) {
                    Color.clear
                        .onAppear {
                            showNewSheet = true
                            
                        }
                }
                .disabled(true)
                
            }
            .overlay(alignment: .bottom) {
                GeometryReader { geometry in
                    Color.clear
                        .contentShape(Circle())
                        .frame(width: 60, height: 60)
                        .position(x: geometry.size.width * 0.87, y: geometry.size.height * 0.98)
                        .onTapGesture {
                            showNewSheet = true
                            
                        }
                }
            }
            .sheet(isPresented: $showNewSheet) {
                NewEventSheetView(data: $eventStore.events)
                
            }
        }
        .onReceive(timer) { _ in
            if SettingsStore().removePassedEvents && SettingsStore().keepEventHistory == false {
                eventStore.deleteExpiredEvents()
                
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventStore())
    
}
