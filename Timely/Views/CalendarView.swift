//
//  CalendarView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-03-25.
//

import SwiftUI

struct CalendarDay: Identifiable, Hashable {
    let id: Int
    let isPlaceholder: Bool
    
    let date: Date?
    
    let year: Int?
    let month: Int?
    let day: Int?
    
    init(id: Int, isPlaceholder: Bool, date: Date? = nil) {
            self.id = id
            self.isPlaceholder = isPlaceholder
            self.date = date
            
            self.year = date != nil ? Calendar.current.component(.year, from: date!) : nil
            self.month = date != nil ? Calendar.current.component(.month, from: date!) : nil
            self.day = date != nil ? Calendar.current.component(.day, from: date!) : nil
        
        }
}

struct CalendarView: View {
    @EnvironmentObject var eventStore: EventStore
    
    @Environment(\.colorScheme) var colorScheme
    var isLightMode: Bool { colorScheme == .light }
    
    @Binding var data: [Event]
    
    @State var month: Int
    @State var year: Int
    
    let saveAction: () -> Void
    
    @State private var showingSettings = false
    
    let columnLayout = Array(repeating: GridItem(spacing: 5, alignment: .center), count: 7)
    
    var currentDay = Calendar.current.component(.day, from: Date())
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    
    func localizedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        
    }
    
    var dayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if let daysOfTheWeek = formatter.shortWeekdaySymbols {
            return daysOfTheWeek
            
        }
        
        return [""]
        
    }
    
    var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if let monthComponents = formatter.monthSymbols {
            return monthComponents
            
        }
        
        return [""]
        
    }
    
    func isCurrentDay(possibleDay: CalendarDay) -> Bool {
        if possibleDay.day == currentDay && possibleDay.month == currentMonth && possibleDay.year == currentYear {
            return true
            
        }
        
        return false
        
    }
    
    var firstDayOfMonth: Int {
        let dateComponents = DateComponents(year: year, month: month)
        guard let startDate = Calendar.current.date(from: dateComponents) else { return 1 }
        
        return Calendar.current.component(.weekday, from: startDate)
        
    }
    
    var totalDaysInMonth: Int {
        let dateComponents = DateComponents(year: year, month: month)
        guard let startDate = Calendar.current.date(from: dateComponents),
            let range = Calendar.current.range(of: .day, in: .month, for: startDate) else {
                return 30
            
            }
        
        return range.count
        
    }
    
    var daysInMonth: [CalendarDay] {
        var days: [CalendarDay] = []
        let placeholderDays = Array(repeating: CalendarDay(id: 0, isPlaceholder: true), count: firstDayOfMonth - 1)
        days.append(contentsOf: placeholderDays)
        for day in 1...totalDaysInMonth {
            
            var components = DateComponents()
            
            components.day = day
            components.month = month
            components.year = year
            
            if let date = Calendar.current.date(from: components) {
                days.append(CalendarDay(id: day, isPlaceholder: false, date: date))
                
            } else {
                print("Invalid date components")
                
            }
        }
        
        return days
        
    }

    func eventsOnDay(searchingDay: CalendarDay) -> [Event] {
        let calendar = Calendar.current
        let searchDay = calendar.startOfDay(for: searchingDay.date ?? Date())
        
        return data.filter { event in
            let startDay = calendar.startOfDay(for: event.dateAndTime)
            let endDay = calendar.startOfDay(for: event.endDateAndTime ?? event.dateAndTime)
            
            return searchDay >= startDay && searchDay <= endDay
            
        }
        
    }
    
    func computedOpacity(day: CalendarDay) -> Double {
        var opacity = 0.4
        
        let multiplier = 0.2
        
        if isCurrentDay(possibleDay: day) && month == currentMonth && year == currentYear {
            opacity = 1.0
            
        } else  {
            opacity += (Double(eventsOnDay(searchingDay: day).count) * multiplier)
            
            if opacity > 0.75 {
                opacity = 0.75
                
            }
            
        }
        
        return opacity
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLightMode {
                    NoiseView()
                    
                }
                
                VStack {
                    // Month navigation bar
                    HStack {
                        Button {
                            if month == 1 {
                                month = 12
                                year -= 1
                                
                            } else {
                                month -= 1
                                
                            }
                            
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        Button("\(monthNames[month - 1]) \(String(year))") {
                            month = currentMonth
                            year = currentYear
                            
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button {
                            if month == 12 {
                                month = 1
                                year += 1
                                
                            } else {
                                month += 1
                                
                            }
                            
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                        }
                        .padding(.trailing, 16)
                        
                    }
                    .padding(.vertical, 12)
                    .background(
                        TileView(inputColours: .accentColor, forceBackground: true, saturationModifier: 0.6, customBorder: true)
                        
                    )
                    .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: 24))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    // Day name headers
                    LazyVGrid(columns: columnLayout) {
                        ForEach(dayNames, id: \.self) { name in
                            Text(name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daysInMonth, id: \.self) { tile in
                            NavigationLink(destination: EventListView(data: $data, dateToDisplay: tile.date) {
                                Task {
                                    do {
                                        try await eventStore.save(events: eventStore.events)
                                        
                                    } catch {
                                        eventStore.saveError = error
                                        
                                    }
                                }
                            }
                                .task {
                                    do {
                                        eventStore.loadFromiCloud()
                                        print("Loading events: ")
                                        
                                        for event in eventStore.events {
                                            print(event.name ?? "Event Name", terminator: " ")
                                            
                                        }
                                        
                                        print("")
                                        
                                    }
                                }) {
                                    if tile.isPlaceholder {
                                        Color.clear
                                            .aspectRatio(0.7, contentMode: .fit)
                                        
                                    } else {
                                        let isCurrent = isCurrentDay(possibleDay: tile)
                                        let dayEvents = eventsOnDay(searchingDay: tile)
                                        let hasEvents = !dayEvents.isEmpty
                                        
                                        VStack(spacing: 4) {
                                            Text(localizedNumber(tile.day!))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                                .font(.title3)
                                                .bold()
                                                .foregroundStyle(.primary)
                                            
                                            let capsuleHeight = 6.0
                                            let capsuleWidth = capsuleHeight / 2 + (capsuleHeight * Double(dayEvents.count))
                                            
                                            Capsule()
                                                .fill(hasEvents ? Color.accentColor : .clear)
                                                .frame(width: min(capsuleWidth, 30), height: capsuleHeight)
                                            
                                            Spacer()
                                            
                                        }
                                        .aspectRatio(0.7, contentMode: .fit)
                                        .background(
                                            TileView(
                                                inputColours: isCurrent ? Color.accentColor : (hasEvents ? Color.accentColor : Color(.black)),
                                                forceBackground: false,
                                                saturationModifier: isCurrent ? 1.0 : (hasEvents ? 0.8 : (isLightMode ? 0.9 : 0.2)),
                                                customBorder: false,
                                                cornerRadius: 12
                                            )
                                            
                                        )
                                        .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: 12))
                                        .shadow(color: isCurrent ? Color.accentColor.opacity(0.4) : .clear, radius: 8)
                                        
                                    }
                                }
                        }
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button() {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
                .navigationBarTitle("Calendar")
            }
        }
    }
}

#Preview {
    let previewData = EventData()
    previewData.events = [
        Event(name: "Sample Event 1", dateAndTime: Date()),
        Event(name: "Sample Event 2", isMuted: true),
        Event(name: "Sample Event 3", isFavourite: true)
        // Add more sample events if needed
    ]
    
    let previewEvents = Binding.constant(previewData.events)
    
    let currentMonth = Calendar.current.component(.month, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    
    return CalendarView(data: previewEvents, month: currentMonth, year: currentYear, saveAction: {})
    
}
