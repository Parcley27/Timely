//
//  CalendarView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-03-25.
//

import SwiftUI

struct CalendarDay: Identifiable {
    let id: Int
    let date: Int
    let isPlaceholder: Bool
}

struct CalendarView: View {
    @Binding var data: [Event]
    
    let saveAction: ()->Void
    
    @State private var showingSettings = false
    
    let columnLayout = Array(repeating: GridItem(spacing: 10, alignment: .center), count: 7)
    
    let month: Int
    let year: Int
    
    var currentDay = Calendar.current.component(.day, from: Date())
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    
    var dayNames: [String] {
        let localCalendar = Calendar(identifier: Calendar.current.identifier)
        let daysOfTheWeek = localCalendar.weekdaySymbols
        
        return daysOfTheWeek
    }
    
    func isCurrentDay(day: CalendarDay) -> Bool {
        if day.date == currentDay && month == currentMonth && year == currentYear {
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
        let placeholderDays = Array(repeating: CalendarDay(id: 0, date: 0, isPlaceholder: true), count: firstDayOfMonth - 1)
        days.append(contentsOf: placeholderDays)
        for day in 1...totalDaysInMonth {
            days.append(CalendarDay(id: day, date: day, isPlaceholder: false))
        }
        
        return days
    }
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    LazyVGrid(columns: columnLayout) {
                        ForEach(dayNames, id: \.self) { name in
                            Text(name)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    LazyVGrid(columns: columnLayout) {
                        ForEach(daysInMonth) { day in
                            if day.isPlaceholder {
                                RoundedRectangle(cornerRadius: 10)
                                    .aspectRatio(1.0, contentMode: ContentMode.fit)
                                    .foregroundStyle(.clear)
                                
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .aspectRatio(1.0, contentMode: ContentMode.fit)
                                        .foregroundStyle(isCurrentDay(day: day) ? Color.accentColor : .secondary)
                                    
                                    Text("\(day.date)")
                                        .foregroundStyle(.background)
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .scrollDisabled(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button() {
                        // SHOW TODAY VIEW
                    } label: {
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
                Settings()
            }
            .navigationBarTitle("Calendar")
            
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
    
    return CalendarView(data: previewEvents, saveAction: {}, month: currentMonth, year: currentYear)
}
