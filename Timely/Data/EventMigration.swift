//
//  EventMigration.swift
//  Timely
//
//  Created by Pierce Nestibo-Oxley on 2026-10-30.
//

import Foundation

struct LegacyRecurrenceFields: Decodable {
    var id: UUID?
    var isRecurring: Bool?
    var recurranceRate: String?
    var recurringTimes: Int?
    var isCopy: Bool?
    var copyOfEventWithID: UUID?
    var copyNumber: Int?
    
    static func decodeList(from data: Data) -> [LegacyRecurrenceFields] {
        guard let failableFields = try? JSONDecoder().decode([FailableLegacyFields].self, from: data) else {
            return []
            
        }
        
        return failableFields.compactMap { $0.fields }
        
    }
}

private struct FailableLegacyFields: Decodable {
    let fields: LegacyRecurrenceFields?
    
    init(from decoder: Decoder) throws {
        fields = try? LegacyRecurrenceFields(from: decoder)
        
    }
}

enum EventMigration {
    private static let maxOccurrences = 5000
    
    private static let maxVirtualBases = 8
    
    // Where the end sits relative to the start, same as the occurrence engine places it
    private struct Ending: Hashable {
        var dayOffset: Int
        var hour: Int
        var minute: Int
        var second: Int
        
    }
    
    private struct Signature: Hashable {
        var name: String?
        var emoji: String?
        var description: String?
        var timing: EventTiming
        var isFavourite: Bool
        var isMuted: Bool
        var ending: Ending? // nill when no end
        
    }
    
    private struct Member {
        let index: Int
        let position: Int // in original array
        let event: Event
        let legacy: LegacyRecurrenceFields
        let signature: Signature
        
    }
    
    private struct Group {
        var masterPosition: Int?
        var copyPositions: [Int] = []
        
    }
    
    static func needsMigration(_ legacy: [LegacyRecurrenceFields]) -> Bool {
        legacy.contains { $0.isCopy == true || $0.copyOfEventWithID != nil || $0.isRecurring == true }
        
    }
    
    static func migrate(_ events: [Event], legacy: [LegacyRecurrenceFields], calendar: Calendar = .current) -> [Event] {
        var legacyByID: [UUID: LegacyRecurrenceFields] = [:]
        
        for entry in legacy {
            if let id = entry.id, legacyByID[id] == nil {
                legacyByID[id] = entry
                
            }
        }
        
        var paired: [Int: LegacyRecurrenceFields] = [:]
        var seenIDs: Set<UUID> = []
        
        for (position, event) in events.enumerated() {
            if seenIDs.insert(event.id).inserted, let entry = legacyByID[event.id] {
                paired[position] = entry
                
            }
        }
        
        let positions = paired.keys.sorted()
        
        // Events that already have a recurrence or a link were made by the new model
        func isLegacyCandidate(_ position: Int) -> Bool {
            events[position].recurrence == nil && events[position].detachedFrom == nil
            
        }
        
        var copies: [Int: UUID] = [:] // position relative to master event
        
        for position in positions where isLegacyCandidate(position) {
            if let masterID = paired[position]?.copyOfEventWithID {
                copies[position] = masterID
                
            }
        }
        
        let referencedIDs = Set(copies.values)
        var groups: [UUID: Group] = [:]
        var order: [UUID] = []
        
        for position in positions where isLegacyCandidate(position) {
            guard let entry = paired[position] else { continue }
            
            if let masterID = copies[position] {
                if groups[masterID] == nil {
                    order.append(masterID)
                    
                }
                
                groups[masterID, default: Group()].copyPositions.append(position)
                
            } else if entry.isCopy != true && entry.copyOfEventWithID == nil && (entry.isRecurring == true || referencedIDs.contains(events[position].id)) {
                let id = events[position].id
                
                if groups[id] == nil {
                    order.append(id)
                    
                }
                
                groups[id, default: Group()].masterPosition = position
                
            }
        }
        
        var run = Run(events: events, paired: paired, calendar: calendar)
        
        for id in order {
            if let group = groups[id] {
                run.migrate(group)
                
            }
        }
        
        return run.finish()
        
    }
    
    private static func frequency(for rate: String?) -> RecurrenceRule.Frequency? {
        switch rate?.lowercased() {
        case "daily":
            return .daily
            
        case "weekly":
            return .weekly
            
        case "monthly":
            return .monthly
            
        case "annually", "annualy", "yearly": // curse me and my old typos
            return .yearly
            
        default:
            return nil
            
        }
    }
    
    private static func signature(of event: Event, calendar: Calendar) -> Signature {
        var ending: Ending?
        
        if let end = event.endDateAndTime {
            if end > event.dateAndTime {
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: event.dateAndTime), to: calendar.startOfDay(for: end)).day ?? 0
                
                let time = calendar.dateComponents([.hour, .minute, .second], from: end)
                
                ending = Ending(dayOffset: max(0, days), hour: time.hour ?? 0, minute: time.minute ?? 0, second: time.second ?? 0)
                
            } else {
                ending = Ending(dayOffset: -1, hour: 0, minute: 0, second: 0)
                
            }
        }
        
        return Signature(name: event.name, emoji: event.emoji, description: event.description, timing: event.timing, isFavourite: event.isFavourite, isMuted: event.isMuted, ending: ending)
        
    }
    
    private static func end(for start: Date, ending: Ending, calendar: Calendar) -> Date {
        guard ending.dayOffset >= 0,
              let day = calendar.date(byAdding: .day, value: ending.dayOffset, to: calendar.startOfDay(for: start)),
              let end = calendar.date(bySettingHour: ending.hour, minute: ending.minute, second: ending.second, of: day),
              end > start else { return start }
              
        return end
        
    }
    
    private static func date(_ date: Date, movedBy periods: Int, frequency: RecurrenceRule.Frequency, calendar: Calendar) -> Date? {
        var offset = DateComponents()
        
        switch frequency {
        case .daily:
            offset.day = periods
            
        case .weekly:
            offset.day = periods * 7
            
        case .monthly:
            offset.month = periods
            
        case .yearly:
            offset.year = periods
            
        }
        
        return calendar.date(byAdding: offset, to: date)
        
    }
    
    private static func isClose(_ first: Date?, _ second: Date?) -> Bool {
        switch (first, second) {
        case (nil, nil):
            return true
            
        case let (first?, second?):
            return abs(first.timeIntervalSince(second)) <= 1
            
        default:
            return false
            
        }
    }
    
    private static func expectedOccurrences(of series: Event, count: Int, calendar: Calendar) -> [(start: Date, end: Date?)]? {
        guard let last = series.lastOccurrence(calendar: calendar) else { return nil }
        
        let lastEnd = max(last.occurrenceDate, last.event.endDateAndTime ?? last.occurrenceDate)
        let window = DateInterval(start: series.dateAndTime, end: lastEnd.addingTimeInterval(1))
        
        let found = series.occurrences(overlapping: window, calendar: calendar)
        
        guard found.count == count else { return nil }
        
        return found.map { (start: $0.event.dateAndTime, end: $0.event.endDateAndTime) }
        
    }
    
    private static func clearLegacy(_ event: inout Event) {
        event.isRecurring = nil
        event.recurranceRate = nil
        event.recurringTimes = nil
        event.isCopy = nil
        event.copyOfEventWithID = nil
        event.copyNumber = nil
        
    }
    
    private struct Plan {
        let merged: Event
        let donorPosition: Int
        let foldedPositions: [Int] // includes group donor for series
        let branches: [(position: Int, event: Event)]
        let excluded: Int
        
    }
    
    private struct Run {
        let paired: [Int: LegacyRecurrenceFields]
        let calendar: Calendar
        
        var events: [Event]
        var removed: Set<Int> = []
        
        var groups = 0
        var series = 0
        var folded = 0
        var detached = 0
        var excluded = 0
        
        init(events: [Event], paired: [Int: LegacyRecurrenceFields], calendar: Calendar) {
            self.events = events
            self.paired = paired
            self.calendar = calendar
            
        }
        
        private func member(at position: Int, index: Int) -> Member? {
            guard let legacy = paired[position] else { return nil }
            
            return Member(index: index, position: position, event: events[position], legacy: legacy, signature: EventMigration.signature(of: events[position], calendar: calendar))
            
        }
        
        private func plan(members: [Member], template: Signature, frequency: RecurrenceRule.Frequency, baseIndex: Int, baseStart: Date, highestIndex: Int) -> Plan? {
            guard highestIndex - baseIndex < EventMigration.maxOccurrences else { return nil }
            
            let count = highestIndex - baseIndex + 1
            
            guard count >= 2 else { return nil }
            
            let rule = RecurrenceRule(frequency: frequency, interval: 1, end: .afterOccurrences(count: count))
            
            var probe = members[0].event
            
            probe.dateAndTime = baseStart
            probe.endDateAndTime = template.ending.map { EventMigration.end(for: baseStart, ending: $0, calendar: calendar) }
            probe.recurrence = rule
            probe.excludedOccurrences = []
            
            guard let expected = EventMigration.expectedOccurrences(of: probe, count: count, calendar: calendar) else { return nil }
            
            var fullMatches: Set<Int> = []
            
            for member in members where member.index >= baseIndex {
                let slot = expected[member.index - baseIndex]
                
                if member.signature == template && EventMigration.isClose(member.event.dateAndTime, slot.start) && EventMigration.isClose(member.event.endDateAndTime, slot.end) {
                    fullMatches.insert(member.index)
                    
                }
            }
            
            guard let donor = members.first(where: { fullMatches.contains($0.index) }) else { return nil }
            
            var merged = donor.event
            
            merged.dateAndTime = expected[0].start
            merged.endDateAndTime = expected[0].end
            merged.recurrence = rule
            merged.excludedOccurrences = []
            
            var membersByIndex: [Int: Member] = [:]
            
            for member in members {
                membersByIndex[member.index] = member
                
            }
            
            var foldedPositions: [Int] = []
            var branches: [(position: Int, event: Event)] = []
            var missing = 0
            var isPinned = false
            
            for (offset, slot) in expected.enumerated() {
                guard let member = membersByIndex[baseIndex + offset] else {
                    // Disclude delted / expired occurences
                    merged.excludedOccurrences.append(slot.start)
                    missing += 1
                    
                    continue
                    
                }
                
                let image = member.event.imageFilename
                
                if fullMatches.contains(member.index) && (image == nil || image == merged.imageFilename) {
                    isPinned = isPinned || member.event.isPinned
                    foldedPositions.append(member.position)
                    
                } else {
                    var branch = member.event
                    branch.detachedFrom = SeriesLink(seriesID: merged.id, occurrenceDate: slot.start)
                    branches.append((position: member.position, event: branch))
                    
                    merged.excludedOccurrences.append(slot.start)
                    
                }
            }
            
            merged.isPinned = isPinned
            
            return Plan(merged: merged, donorPosition: donor.position, foldedPositions: foldedPositions, branches: branches, excluded: missing)
            
        }
        
        mutating func migrate(_ group: Group) {
            groups += 1
            
            var members: [Member] = []
            var usedIndexes: Set<Int> = []
            
            if let position = group.masterPosition, let master = member(at: position, index: 0) {
                members.append(master)
                usedIndexes.insert(0)
                
            }
            
            for position in group.copyPositions {
                // just create a new event if there's some old copy number shenanigans
                guard let number = paired[position]?.copyNumber, number > 0, usedIndexes.insert(number).inserted else {
                    continue
                
                }
                
                if let copy = member(at: position, index: number) {
                    members.append(copy)
                    
                }
            }
            
            members.sort { $0.index < $1.index }
            
            let master = members.first { $0.index == 0 }
            let firstCopy = members.first { $0.index > 0 }
            
            guard members.count >= 2,
                  let frequency = EventMigration.frequency(for: master?.legacy.recurranceRate ?? firstCopy?.legacy.recurranceRate) else { return }
            
            // Majority vote on event importance, else jsut do whatever the master is
            var votes: [Signature: Int] = [:]
            
            for member in members {
                votes[member.signature, default: 0] += 1
                
            }
            
            var template = members[0].signature
            var mostVotes = 0
            
            for member in members where votes[member.signature, default: 0] > mostVotes {
                template = member.signature
                mostVotes = votes[member.signature, default: 0]
                
            }
            
            var highestIndex = members[members.count - 1].index
            
            if let master {
                let recurringTimes = min(max(master.legacy.recurringTimes ?? 0, 0), EventMigration.maxOccurrences + 1)
                
                highestIndex = max(highestIndex, recurringTimes - 1)
                
            }
            
            var bases: [(index: Int, start: Date)] = []
            let matching = members.filter { $0.signature == template }
            
            if let master {
                bases.append((index: 0, start: master.event.dateAndTime))
                
            } else {
                bases.append((index: matching[0].index, start: matching[0].event.dateAndTime))
                
                for member in matching.prefix(EventMigration.maxVirtualBases) {
                    if let start = EventMigration.date(member.event.dateAndTime, movedBy: -member.index, frequency: frequency, calendar: calendar) {
                        bases.append((index: 0, start: start))
                        
                    }
                }
            }
            
            var best: Plan?
            
            for base in bases {
                guard let candidate = plan(members: members, template: template, frequency: frequency, baseIndex: base.index, baseStart: base.start, highestIndex: highestIndex) else { continue }
                
                if candidate.foldedPositions.count > (best?.foldedPositions.count ?? 0) {
                    best = candidate
                    
                }
                
                if (best?.foldedPositions.count ?? 0) >= matching.count {
                    break
                    
                }
            }
            
            guard let best else { return }
            
            for branch in best.branches {
                events[branch.position] = branch.event
                
            }
            
            removed.formUnion(best.foldedPositions.filter { $0 != best.donorPosition })
            events[best.donorPosition] = best.merged
            
            series += 1
            folded += best.foldedPositions.count
            detached += best.branches.count
            excluded += best.excluded
            
        }
        
        func finish() -> [Event] {
            var output: [Event] = []
            
            for (position, event) in events.enumerated() where !removed.contains(position) {
                var cleared = event
                EventMigration.clearLegacy(&cleared)
                
                output.append(cleared)
                
            }
            
            print("Migration Complete!")
            print("\(groups) groups, \(series) series, \(folded) recurrance compressions, \(detached) detached, \(excluded) excluded")
            
            return output
            
        }
    }
}
