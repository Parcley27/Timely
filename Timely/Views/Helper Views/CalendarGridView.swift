//
//  CalendarGridView.swift
//  Timely
//
//  Created by Pierce Nestibo-Oxley on 2026-06-29.
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

struct MonthGridView: View {
    let month: Int
    let year: Int
    
    @Binding var data: [Event]
    
    let isLightMode: Bool
    let isDragging: Bool
    let saveAction: () -> Void
    
    private let currentDay = Calendar.current.component(.day, from: Date())
    private let currentMonth = Calendar.current.component(.month, from: Date())
    private let currentYear = Calendar.current.component(.year, from: Date())
    
    private func localizedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
        
    }
    
    private func firstDayOfMonth() -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        
        guard let startDate = Calendar.current.date(from: dateComponents) else { return 1 }
        
        let weekday = Calendar.current.component(.weekday, from: startDate)
        let firstWeekday = Calendar.current.firstWeekday
        
        return (weekday - firstWeekday + 7) % 7 + 1
        
    }
    
    private func totalDaysInMonth() -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        
        guard let startDate = Calendar.current.date(from: dateComponents),
              let range = Calendar.current.range(of: .day, in: .month, for: startDate) else {
            return 30
            
        }
        
        return range.count
        
    }
    
    private var days: [CalendarDay] {
        var result: [CalendarDay] = Array(repeating: CalendarDay(id: 0, isPlaceholder: true), count: firstDayOfMonth() - 1)
        
        for day in 1 ... totalDaysInMonth() {
            var components = DateComponents()
            
            components.day = day
            components.month = month
            components.year = year
            
            if let date = Calendar.current.date(from: components) {
                result.append(CalendarDay(id: day, isPlaceholder: false, date: date))
                
            }
        }
        
        return result
        
    }
    
    private func isCurrentDay(_ day: CalendarDay) -> Bool {
        day.day == currentDay && day.month == currentMonth && day.year == currentYear
        
    }
    
    private func eventsOnDay(_ day: CalendarDay) -> [Event] {
        let calendar = Calendar.current
        let searchDay = calendar.startOfDay(for: day.date ?? Date())
        
        return data.filter { event in
            let startDay = calendar.startOfDay(for: event.dateAndTime)
            let endDay = calendar.startOfDay(for: event.endDateAndTime ?? event.dateAndTime)
            
            return (searchDay >= startDay && searchDay <= endDay) ||
                   (event.isAllDay ?? false && calendar.isDate(event.dateAndTime, equalTo: day.date!, toGranularity: .day))
            
        }
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(days, id: \.self) { tile in
                NavigationLink(destination: EventListView(data: $data, dateToDisplay: tile.date) {
                    saveAction()
                }) {
                    if tile.isPlaceholder {
                        Color.clear
                            .aspectRatio(0.7, contentMode: .fit)
                        
                    } else {
                        let isCurrent = isCurrentDay(tile)
                        let dayEvents = eventsOnDay(tile)
                        let hasEvents = !dayEvents.isEmpty
                        
                        VStack(spacing: 4) {
                            Text(localizedNumber(tile.day!))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                                .font(.title3)
                                .bold()
//                                .foregroundStyle(isCurrent ? Color.primary.adjusted(saturation: isLightMode ? 0.0 : 1.0, brightness: isLightMode ? 1.0 : 2.0) : .primary)
                                .foregroundStyle(isCurrent ? (isLightMode ? .white : .black) : .secondary)
                            
                            let capsuleHeight = 6.0
                            let capsuleWidth = capsuleHeight / 2 + (capsuleHeight * Double(dayEvents.count))
                            
                            Capsule()
                                .fill(hasEvents ? (isCurrent ? .white : Color.accentColor) : .clear)
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
                        .shadow(color: isCurrent ? Color.accentColor.opacity(0.8) : .clear, radius: 8)
                    }
                }
            }
            .padding(.vertical, 2)
            
        }
        .allowsHitTesting(!isDragging)
        
    }
}

#Preview {
    let previewPreferences = SettingsStore()
    
    let previewData = EventData()
    previewData.events = [
        Event(name: "Sample Event 1", dateAndTime: Date()),
        Event(name: "Sample Event 2", isMuted: true),
        Event(name: "Sample Event 3", isFavourite: true)
        
    ]
    
    let previewEvents = Binding.constant(previewData.events)
    
    let currentMonth = Calendar.current.component(.month, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    
    return CalendarView(data: previewEvents, displayMonth: currentMonth, displayYear: currentYear, saveAction: {})
        .environmentObject(previewPreferences)
    
}
