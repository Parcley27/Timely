//
//  EventDateTimeSection.swift
//  Timely
//
//  Created by Pierce Nestibo-Oxley on 2026-10-29.
//

import SwiftUI

struct EventDateTimeSection: View {
    @Binding var start: Date
    @Binding var previousStart: Date
    
    // always save old end time if they switch between point/all day and timed
    @Binding var end: Date
        
    @Binding var timing: EventTiming
    
    var startRange: ClosedRange<Date>? = nil
    
    private var startLabel: LocalizedStringKey {
        timing == .moment ? "Time" : "Start Time"
        
    }
    
    private var timesAfterStart: ClosedRange<Date> {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start)
        let startDate = calendar.date(from: startComponents)!
        
        let endComponents = DateComponents(year: 10000, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let endDate = calendar.date(from: endComponents)!
        
        return startDate...endDate
        
    }
    
    private func setTime(for date: Date, hour: Int, minute: Int, second: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return calendar.date(from: components)
        
    }
    
    @ViewBuilder
    private var startPicker: some View {
        if let startRange {
            DatePicker(startLabel, selection: $start, in: startRange, displayedComponents: [.date, .hourAndMinute])
            
        } else {
            DatePicker(startLabel, selection: $start, displayedComponents: [.date, .hourAndMinute])
            
        }
    }
    
    var body: some View {
        Section("Date and Time") {
            Picker("Timing", selection: $timing) {
                Text("Timed").tag(EventTiming.timed)
                Text("All Day").tag(EventTiming.allDay)
                Text("Moment").tag(EventTiming.moment)
                
            }
            .pickerStyle(.segmented)
            
            startPicker
                .datePickerStyle(.compact)
                .opacity(timing != .allDay ? 1.0 : 0.5)
                
            if timing != .moment {
                DatePicker("End Time", selection: $end, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .opacity(timing != .allDay ? 1.0 : 0.5)
                    .disabled(timing == .allDay)
                    
            }
        }
        .onChange(of: timing) { _, newValue in
            if newValue == .allDay {
                start = setTime(for: start, hour: 0, minute: 0, second: 0) ?? start
                end = setTime(for: start, hour: 23, minute: 59, second: 59) ?? end
                
            }
        }
        .onChange(of: start) { _, _ in
            if timing == .allDay {
                end = setTime(for: start, hour: 23, minute: 59, second: 59) ?? end
                
            } else {
                let eventLength = end.timeIntervalSince(previousStart)
                
                end = start.addingTimeInterval(eventLength)
                
            }
            
            previousStart = start
            
        }
    }
}
