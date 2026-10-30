//
//  EventRecurrence.swift
//  Timely
//
//  Created by Pierce Nestibo-Oxley on 2026-10-29.
//

import Foundation

// more complex recurrances have to be optional later
struct RecurrenceRule: Codable, Hashable {
    enum Frequency: String, Codable, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly
        
    }
    
    enum End: Codable, Hashable {
        case never
        case onDate(date: Date)
        case afterOccurrences(count: Int)
        
    }
    
    var frequency: Frequency
    var interval: Int = 1
    var daysOfWeek: [Int]? = nil // weekly only
    var end: End = .never
    
}

// denote which recurrance pattern a given event was split from
struct SeriesLink: Codable, Hashable {
    var seriesID: UUID
    var occurrenceDate: Date // original start of og recurrance pattern
    
}

struct EventOccurrence: Identifiable, Hashable {
    let event: Event
    let occurrenceDate: Date
    var seriesID: UUID { event.id }
    // One-offs keep the plain event id, so editing their date doesn't change list identity
    var id: String { event.isRepeating ? "\(seriesID.uuidString)-\(occurrenceDate.timeIntervalSinceReferenceDate)" : seriesID.uuidString }
    
}

extension Event {
    var isRepeating: Bool { recurrence != nil }
    
    func occurrences(overlapping interval: DateInterval, calendar: Calendar = .current) -> [EventOccurrence] {
        let series = OccurrenceSeries(event: self, calendar: calendar)
        
        return series.instances(overlapping: interval).map { makeOccurrence($0) }
        
    }
    
    func nextOccurrence(after date: Date = Date(), calendar: Calendar = .current) -> EventOccurrence? {
        let series = OccurrenceSeries(event: self, calendar: calendar)
        
        return series.nextInstance(after: date).map { makeOccurrence($0) }
        
    }
    
    func lastOccurrence(calendar: Calendar = .current) -> EventOccurrence? {
        let series = OccurrenceSeries(event: self, calendar: calendar)
        
        return series.lastInstance().map { makeOccurrence($0) }
        
    }
    
    func displayOccurrence(at now: Date = Date(), calendar: Calendar = .current) -> EventOccurrence {
        // Called per event on every list and badge refresh
        guard isRepeating else { return EventOccurrence(event: self, occurrenceDate: dateAndTime) }
        
        return nextOccurrence(after: now, calendar: calendar)
            ?? lastOccurrence(calendar: calendar)
            ?? EventOccurrence(event: self, occurrenceDate: dateAndTime)
            
    }
    
    func occurrence(startingOn date: Date, calendar: Calendar = .current) -> EventOccurrence? {
        let series = OccurrenceSeries(event: self, calendar: calendar)
        
        return series.instance(startingOn: date).map { makeOccurrence($0) }
        
    }
    
    func remainingOccurrences(after occurrence: EventOccurrence, calendar: Calendar = .current) -> Int? {
        guard let recurrence, case .afterOccurrences = recurrence.end else { return nil }
        
        return OccurrenceSeries(event: self, calendar: calendar).remaining(after: occurrence.occurrenceDate)
        
    }
    
    func continuationSummary(after occurrence: EventOccurrence, calendar: Calendar = .current) -> String? {
        guard let recurrence else { return nil }
        
        let boundary = max(occurrence.event.endDateAndTime ?? occurrence.occurrenceDate, occurrence.occurrenceDate)
        
        guard nextOccurrence(after: boundary, calendar: calendar) != nil else {
            return NSLocalizedString("Last occurrence", comment: "")
            
        }
        
        var summary = recurrence.cadenceSummary(calendar: calendar)
        
        switch recurrence.end {
        case .never:
            break
            
        case .afterOccurrences:
            if let remaining = remainingOccurrences(after: occurrence, calendar: calendar), remaining > 0 {
                summary += " · " + String.localizedStringWithFormat(NSLocalizedString("%lld more", comment: ""), remaining)
                
            }
            
        case .onDate(let date):
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = calendar.locale ?? Locale.current
            formatter.setLocalizedDateFormatFromTemplate(calendar.isDate(date, equalTo: Date(), toGranularity: .year) ? "dMMM" : "dMMMy")
            
            summary += " · " + String.localizedStringWithFormat(NSLocalizedString("until %@", comment: ""), formatter.string(from: date))
            
        }
        
        return summary
        
    }
    
    private func makeOccurrence(_ instance: OccurrenceSeries.Instance) -> EventOccurrence {
        guard instance.index > 0 else {
            return EventOccurrence(event: self, occurrenceDate: dateAndTime)
            
        }
        
        var moved = self
        moved.dateAndTime = instance.start
        moved.endDateAndTime = instance.end
        
        return EventOccurrence(event: moved, occurrenceDate: instance.start)
        
    }
}

extension RecurrenceRule {
    // x, then every abc
    func cadenceSummary(calendar: Calendar = .current) -> String {
        let step = max(1, interval)
        
        if frequency == .weekly {
            let weekdays = Set((daysOfWeek ?? []).filter { (1...7).contains($0) })
            
            if !weekdays.isEmpty {
                let symbols = calendar.shortWeekdaySymbols
                
                let names = weekdays
                    .sorted { ($0 - calendar.firstWeekday + 7) % 7 < ($1 - calendar.firstWeekday + 7) % 7 }
                    .map { symbols[$0 - 1] }
                    
                let days = ListFormatter.localizedString(byJoining: names)
                
                if step == 1 {
                    return String.localizedStringWithFormat(NSLocalizedString("Then every week on %@", comment: ""), days)
                    
                }
                
                return String.localizedStringWithFormat(NSLocalizedString("Then every %lld weeks on %@", comment: ""), step, days)
                
            }
        }
        
        switch frequency {
        case .daily:
            if step == 1 { return NSLocalizedString("Then every day", comment: "") }
            
            return String.localizedStringWithFormat(NSLocalizedString("Then every %lld days", comment: ""), step)
            
        case .weekly:
            if step == 1 { return NSLocalizedString("Then every week", comment: "") }
            
            return String.localizedStringWithFormat(NSLocalizedString("Then every %lld weeks", comment: ""), step)
            
        case .monthly:
            if step == 1 { return NSLocalizedString("Then every month", comment: "") }
            
            return String.localizedStringWithFormat(NSLocalizedString("Then every %lld months", comment: ""), step)
            
        case .yearly:
            if step == 1 { return NSLocalizedString("Then every year", comment: "") }
            
            return String.localizedStringWithFormat(NSLocalizedString("Then every %lld years", comment: ""), step)
            
        }
    }
}

extension Array where Element == Event {
    func occurrences(overlapping interval: DateInterval, hideExpired: Bool, calendar: Calendar = .current) -> [EventOccurrence] {
        let found = flatMap { $0.occurrences(overlapping: interval, calendar: calendar) }
        
        return hideExpired ? found.filter { !$0.event.hasExpired() } : found
        
    }
}

private struct OccurrenceSeries {
    static let maxSteps = 5000
    
    struct Instance {
        let index: Int
        let start: Date
        let end: Date?
        
        // moment events
        var isSpan: Bool {
            guard let end else { return false }
            
            return end > start
            
        }
        
        func overlaps(_ window: DateInterval) -> Bool {
            guard start < window.end else { return false }
            
            if isSpan, let end {
                return end > window.start
                
            }
            
            return start >= window.start
            
        }
        
        func isOngoingOrUpcoming(at date: Date) -> Bool {
            if isSpan, let end {
                return end > date
                
            }
            
            return start > date
            
        }
    }
    
    struct WeeklyDays {
        let firstDay: Date // start of the user week
        let offsets: [Int] // selected days as offsets from firstDay
        let time: DateComponents
        let firstWeek: [Date]
        
    }
    
    let calendar: Calendar
    let anchor: Date
    let anchorEnd: Date?
    let frequency: RecurrenceRule.Frequency
    let interval: Int
    let maxCount: Int?
    let endLimit: Date? // inclusive of final day
    let duration: DateComponents? // nil for moments
    let excludedDays: Set<Date>
    let weeklyDays: WeeklyDays?
    
    init(event: Event, calendar: Calendar) {
        let rule = event.recurrence ?? RecurrenceRule(frequency: .daily, end: .afterOccurrences(count: 1))
        
        self.calendar = calendar
        anchor = event.dateAndTime
        anchorEnd = event.endDateAndTime
        frequency = rule.frequency
        interval = max(1, rule.interval)
        
        switch rule.end {
        case .never:
            maxCount = nil
            endLimit = nil
            
        case .afterOccurrences(let count):
            maxCount = max(1, count)
            endLimit = nil
            
        case .onDate(let date):
            let endDay = calendar.startOfDay(for: date)
            
            maxCount = nil
            endLimit = calendar.date(byAdding: .day, value: 1, to: endDay).map { calendar.startOfDay(for: $0) } ?? endDay
            
        }
        
        if let end = event.endDateAndTime {
            duration = end > event.dateAndTime ? calendar.dateComponents([.day, .hour, .minute, .second], from: event.dateAndTime, to: end) : DateComponents()
            
        } else {
            duration = nil
            
        }
        
        // match by day in case of time zone stuff
        excludedDays = event.recurrence == nil ? [] : Set(event.excludedOccurrences.map { calendar.startOfDay(for: $0) })
        
        let weekdays = Set((rule.daysOfWeek ?? []).filter { (1...7).contains($0) })
        
        if rule.frequency == .weekly, !weekdays.isEmpty, let week = calendar.dateInterval(of: .weekOfYear, for: event.dateAndTime) {
            let offsets = weekdays.map { ($0 - calendar.firstWeekday + 7) % 7 }.sorted()
            let time = calendar.dateComponents([.hour, .minute, .second], from: event.dateAndTime)
            
            let firstWeek = offsets
                .compactMap { OccurrenceSeries.day($0, of: week.start, at: time, calendar: calendar) }
                .filter { $0 > event.dateAndTime }
                
            weeklyDays = WeeklyDays(firstDay: week.start, offsets: offsets, time: time, firstWeek: firstWeek)
            
        } else {
            weeklyDays = nil
            
        }
    }
    
    private static func day(_ offset: Int, of weekStart: Date, at time: DateComponents, calendar: Calendar) -> Date? {
        guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
        
        return calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0, of: day)
        
    }
    
    private func product(_ a: Int, _ b: Int) -> Int? {
        let (value, overflow) = a.multipliedReportingOverflow(by: b)
        
        return overflow ? nil : value
        
    }
    
    private func days(from start: Date, to end: Date) -> Int {
        max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0)
        
    }
    
    // ignores  series end and exclusions
    func start(at index: Int) -> Date? {
        guard index >= 0 else { return nil }
        
        if index == 0 { return anchor }
        
        if let weeklyDays {
            let first = 1 + weeklyDays.firstWeek.count
            
            if index < first { return weeklyDays.firstWeek[index - 1] }
            
            let rest = index - first
            let perWeek = weeklyDays.offsets.count
            
            guard let weeks = product(rest / perWeek + 1, interval),
                  let days = product(weeks, 7),
                  let weekStart = calendar.date(byAdding: .day, value: days, to: weeklyDays.firstDay) else { return nil }
                  
            return OccurrenceSeries.day(weeklyDays.offsets[rest % perWeek], of: weekStart, at: weeklyDays.time, calendar: calendar)
            
        }
        
        guard let periods = product(interval, index) else { return nil }
        
        var offset = DateComponents()
        
        switch frequency {
        case .daily:
            offset.day = periods
            
        case .weekly:
            guard let days = product(periods, 7) else { return nil }
            offset.day = days
            
        case .monthly:
            offset.month = periods
            
        case .yearly:
            offset.year = periods
            
        }
        
        return calendar.date(byAdding: offset, to: anchor)
        
    }
    
    func instance(at index: Int) -> Instance? {
        guard let start = start(at: index) else { return nil }
        
        if index > 0 {
            if let maxCount, index >= maxCount { return nil }
            if let endLimit, start >= endLimit { return nil }
            
        }
        
        let end: Date?
        
        if index == 0 {
            end = anchorEnd
            
        } else if let duration {
            end = calendar.date(byAdding: duration, to: start) ?? start
            
        } else {
            end = nil
            
        }
        
        return Instance(index: index, start: start, end: end)
        
    }
    
    func isExcluded(_ instance: Instance) -> Bool {
        excludedDays.contains(calendar.startOfDay(for: instance.start))
        
    }
    
    // indices at or before the first occurrence on some day
    func indexNear(_ date: Date) -> Int {
        guard date > anchor else { return 0 }
        
        let estimate: Int
        
        if let weeklyDays {
            let step = days(from: weeklyDays.firstDay, to: date) / (product(interval, 7) ?? Int.max)
            
            estimate = step == 0 ? 0 : 1 + weeklyDays.firstWeek.count + (step - 1) * weeklyDays.offsets.count
            
        } else {
            switch frequency {
            case .daily:
                estimate = days(from: anchor, to: date) / interval
                
            case .weekly:
                estimate = days(from: anchor, to: date) / (product(interval, 7) ?? Int.max)
                
            case .monthly:
                estimate = (calendar.dateComponents([.month], from: anchor, to: date).month ?? 0) / interval
                
            case .yearly:
                estimate = (calendar.dateComponents([.year], from: anchor, to: date).year ?? 0) / interval
                
            }
        }
        
        return max(0, estimate - 1)
        
    }
    
    func lookback(from date: Date) -> Date {
        guard let duration else { return date }
        
        var back = DateComponents()
        back.day = -(duration.day ?? 0)
        back.hour = -(duration.hour ?? 0)
        back.minute = -(duration.minute ?? 0)
        back.second = -(duration.second ?? 0)
        
        return calendar.date(byAdding: back, to: date) ?? date
        
    }
    
    // includes excluded occurrences
    func firstInstance(startingAtOrAfter date: Date) -> Instance? {
        var index = indexNear(date)
        
        for _ in 0..<OccurrenceSeries.maxSteps {
            guard let found = instance(at: index) else { return nil }
            
            if found.start >= date { return found }
            
            index += 1
            
        }
        
        return nil
        
    }
    
    func instances(overlapping window: DateInterval) -> [Instance] {
        var result: [Instance] = []
        var index = indexNear(lookback(from: window.start))
        
        for _ in 0..<OccurrenceSeries.maxSteps {
            guard let found = instance(at: index), found.start < window.end else { break }
            
            if !isExcluded(found) && found.overlaps(window) {
                result.append(found)
                
            }
            
            index += 1
            
        }
        
        return result
        
    }
    
    func nextInstance(after date: Date) -> Instance? {
        var index = indexNear(lookback(from: date))
        
        for _ in 0..<OccurrenceSeries.maxSteps {
            guard let found = instance(at: index) else { return nil }
            
            if !isExcluded(found) && found.isOngoingOrUpcoming(at: date) { return found }
            
            index += 1
            
        }
        
        return nil
        
    }
    
    func lastInstance() -> Instance? {
        var index: Int
        
        if let maxCount {
            index = maxCount - 1
            
        } else if let endLimit {
            index = indexNear(endLimit)
            
            for _ in 0..<OccurrenceSeries.maxSteps {
                guard index > 0, instance(at: index) == nil else { break }
                
                index -= 1
                
            }
            
            for _ in 0..<OccurrenceSeries.maxSteps {
                guard instance(at: index + 1) != nil else { break }
                
                index += 1
                
            }
            
        } else {
            return nil
            
        }
        
        for _ in 0..<OccurrenceSeries.maxSteps {
            guard index >= 0 else { return nil }
            
            if let found = instance(at: index), !isExcluded(found) { return found }
            
            index -= 1
            
        }
        
        return nil
        
    }
    
    func instance(startingOn date: Date) -> Instance? {
        let day = calendar.startOfDay(for: date)
        
        guard let found = firstInstance(startingAtOrAfter: day),
              calendar.startOfDay(for: found.start) == day,
              !isExcluded(found) else { return nil }
              
        return found
        
    }
    
    // non-excluded occurrences after date
    func remaining(after date: Date) -> Int? {
        guard let maxCount else { return nil }
        guard let next = firstInstance(startingAtOrAfter: date) else { return 0 }
        
        let firstAfter = next.start == date ? next.index + 1 : next.index
        var remaining = max(0, maxCount - firstAfter)
        
        // exclusions that fall on a remaining occurrence
        for day in excludedDays {
            if let match = firstInstance(startingAtOrAfter: day), match.index >= firstAfter, calendar.startOfDay(for: match.start) == day {
                remaining -= 1
                
            }
        }
        
        return max(0, remaining)
        
    }
}
