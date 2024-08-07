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
    @StateObject private var eventList = EventStore()
    
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
        var matchingEvents = [Event(name: "")]
        matchingEvents.removeAll()
        
        let matchingYear = searchingDay.year
        let matchingMonth = searchingDay.month
        let matchingDay = searchingDay.day
        
        for event in data {
            for occuringDate in event.isOnDates {
                let eventYear = Calendar.current.component(.year, from: occuringDate)
                let eventMonth = Calendar.current.component(.month, from: occuringDate)
                let eventDay = Calendar.current.component(.day, from: occuringDate)
                
                if matchingYear == eventYear && matchingMonth == eventMonth && matchingDay == eventDay {
                    matchingEvents.append(event)
                    
                    break
                    
                }
            }
        }
        
        return matchingEvents
        
    }
    
    func computedOpacity(day: CalendarDay) -> Double {
        var opacity = 1.0
        
        let multiplier = 0.15
        
        if isCurrentDay(possibleDay: day) && month == currentMonth && year == currentYear {
            opacity = 1.0
            
        } else  {
            opacity = 0.4 + (Double(eventsOnDay(searchingDay: day).count) * multiplier)
            if opacity > 0.75 {
                opacity = 0.75
                
            }
            
        }
        
        return opacity
        
    }
    
    var body: some View {
        NavigationStack {
                HStack {
                    Button() {
                        if month == 1 {
                            month = 12
                            year -= 1
                            
                        } else {
                            month -= 1
                            
                        }
                        
                    } label: {
                        Image(systemName: "lessthan")
                            .font(.title)
                        
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                    //.padding(.leading)
                    //.padding(.trailing, 10)
                    .background(.ultraThickMaterial , in: RoundedRectangle(cornerRadius: 25.0))
                    
                    Button("\(monthNames[month - 1]) \(String(year))") {
                        month = currentMonth
                        year = currentYear
                        
                    }
                    .font(.title2)
                    .frame(width: 170)
                    
                    
                    Button() {
                        if month == 12 {
                            month = 1
                            year += 1
                            
                        } else {
                            month += 1
                            
                        }
                    } label: {
                        Image(systemName: "greaterthan")
                            .font(.title)
                        
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                    //.padding(.leading, 20)
                    //.padding(.trailing, 8)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 25.0))
                    
                }
                .background(.bar, in: RoundedRectangle(cornerRadius: 25.0))
                
                VStack {
                    LazyVGrid(columns: columnLayout) {
                        ForEach(dayNames, id: \.self) { name in
                            Text(name)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal)
                    //.padding(.top)
                    
                    LazyVGrid(columns: columnLayout, spacing: 5) {
                        ForEach(daysInMonth, id: \.self) { tile in
                            NavigationLink(destination: EventListView(data: $data, dateToDisplay: tile.date) {
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
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .aspectRatio(0.9, contentMode: .fit)
                                        .foregroundStyle(tile.isPlaceholder ? .clear : isCurrentDay(possibleDay: tile) ? Color.accentColor : .primary)
                                        .opacity(computedOpacity(day: tile))
                                    
                                    if !tile.isPlaceholder {
                                        VStack(spacing: 4) {
                                            Text(localizedNumber(tile.day!))
                                                .foregroundStyle(.background)
                                                .font(.title2)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                                .bold()
                                            
                                            Image(systemName: "circle.fill")
                                                .resizable()
                                                .opacity(eventsOnDay(searchingDay: tile).count > 0 ? 1.0 : 0.0)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 8, height: 12, alignment: .top)
                                                .foregroundStyle(.background)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: EventListView(data: $data, dateToDisplay: Date()) {
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
                        }) {
                            Text("Today")
                        }
                    }
                    
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
                //.navigationBarTitle("\(monthNames[month - 1]) \(String(year))")
            
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
