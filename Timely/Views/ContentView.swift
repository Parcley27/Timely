//
//  ContentView.swift
//  Timely
//
//  Created by Pierce Oxley on 12/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var preferences: SettingsStore
    
    @State var lastTab: Int = 0
    @State private var showNewSheet: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    
    var buttonSize: CGFloat = 80
    
    var plusButton: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.blue, lineWidth: buttonSize * 0.075)
                .frame(width: buttonSize, height: buttonSize)
            
            Image(systemName: "plus")
                .foregroundStyle(Color.blue)
                .font(.system(size: buttonSize * 0.75))
            
        }
        .glassEffect()
        
    }
    
    func filterPassedEvents(events: [Event]) -> [Event]? {
        var passedEvents = events.filter { $0.hasPassed == true }
        passedEvents = passedEvents.filter { $0.isMuted == false }
        
        if preferences.removePassedEvents {
            passedEvents = passedEvents.filter { $0.hasExpired() == false }
            
        }
        
        if preferences.showBadge {
            return passedEvents
            
        } else {
            return []
            
        }
    }
    
    func localizedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        
    }
    var badgeCount: Int {
        return filterPassedEvents(events: eventStore.events)?.count ?? 0
    }
    
    var shouldShowBadge: Bool {
        return preferences.showBadge && badgeCount > 0
    }
    

    
    var body: some View {
        ZStack {
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
                        
                    }
                    .badge(shouldShowBadge ? Text(localizedNumber(badgeCount)) : nil)
                    
                    if preferences.useLegacyLayout {
                        Tab("", systemImage: "") {
                            
                        }
                        .disabled(true)
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
                    
                    if !preferences.useLegacyLayout {
                        Tab("New Event", systemImage: "plus", role: .search) {
                            Color.clear
                                .onAppear {
                                    showNewSheet = true
                                    
                                }
                        }
                    }
                }
                .id(preferences.useLegacyLayout) // Force to rerender when layout preference changes
                .overlay(alignment: .bottom) {
                    GeometryReader { geometry in // New button collider
                        Color.red
                            .opacity(0)
                            .contentShape(Circle())
                            .frame(width: 60, height: 60)
                            .position(x: geometry.size.width * 0.87, y: geometry.size.height * 0.98)
                            .onTapGesture {
                                if !preferences.useLegacyLayout {
                                    showNewSheet = true
                                    
                                }
                            }
                    }
                }
                .sheet(isPresented: $showNewSheet) {
                    NewEventSheetView(data: $eventStore.events)
                    
                }
            }
            .onReceive(timer) { _ in
                if preferences.removePassedEvents && preferences.keepEventHistory == false {
                    eventStore.deleteExpiredEvents()
                    
                }
            }
            
            if preferences.useLegacyLayout {
                GeometryReader { metrics in
                    plusButton
                        .frame(width: metrics.size.width / 7, height: metrics.size.height / 11.0)
                        .position(x: metrics.size.width * 0.5, y: metrics.size.height * 0.94)
                    
                }
            }
        }
        .overlay(alignment: .bottom) { // Legacy button collider
            GeometryReader { geometry in
                Color.red
                    .opacity(0)
                    .contentShape(Circle())
                    .frame(width: buttonSize, height: buttonSize * 1.25)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.95)
                    .onTapGesture {
                        if preferences.useLegacyLayout {
                            showNewSheet = true
                            
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventStore())
        .environmentObject(SettingsStore())
    
}
