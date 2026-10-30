//
//  Event Extensions.swift
//  Timely
//
//  Created by Pierce Nestibo-Oxley on 2026-10-29.
//

import Foundation

extension Event {
    // Old property names
    enum CodingKeys: String, CodingKey {
        case name
        case emoji
        case imageFilename
        case description
        case dateAndTime
        case endDateAndTime
        case timing
        case isAllDay // read only, for data saved before timing existed
        case recurrence
        case excludedOccurrences
        case detachedFrom
        case isRecurring
        case recurranceRate
        case recurringTimes
        case isCopy
        case copyOfEventWithID
        case copyNumber
        case isFavourite
        case isMuted
        case isPinned
        case id
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode if present for all optional types, else force decode
        name = try container.decodeIfPresent(String.self, forKey: .name)
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        dateAndTime = try container.decode(Date.self, forKey: .dateAndTime)
        endDateAndTime = try container.decodeIfPresent(Date.self, forKey: .endDateAndTime)
        
        // translate old timings to new recurrance rules
        if let decodedTiming = try? container.decodeIfPresent(EventTiming.self, forKey: .timing) {
            timing = decodedTiming
            
        } else if try container.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? false {
            timing = .allDay
            
        } else if endDateAndTime == nil || dateAndTime == endDateAndTime {
            timing = .moment
            
        } else {
            timing = .timed
            
        }
        
        recurrence = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence)
        excludedOccurrences = try container.decodeIfPresent([Date].self, forKey: .excludedOccurrences) ?? []
        detachedFrom = try container.decodeIfPresent(SeriesLink.self, forKey: .detachedFrom)
        
        isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring)
        recurranceRate = try container.decodeIfPresent(String.self, forKey: .recurranceRate)
        recurringTimes = try container.decodeIfPresent(Int.self, forKey: .recurringTimes)
        
        isCopy = try container.decodeIfPresent(Bool.self, forKey: .isCopy)
        copyOfEventWithID = try container.decodeIfPresent(UUID.self, forKey: .copyOfEventWithID)
        copyNumber = try container.decodeIfPresent(Int.self, forKey: .copyNumber)
        
        isFavourite = try container.decodeIfPresent(Bool.self, forKey: .isFavourite) ?? false
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false
        
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(emoji, forKey: .emoji)
        try container.encodeIfPresent(imageFilename, forKey: .imageFilename)
        try container.encodeIfPresent(description, forKey: .description)
        
        try container.encode(dateAndTime, forKey: .dateAndTime)
        try container.encodeIfPresent(endDateAndTime, forKey: .endDateAndTime)
        try container.encode(timing, forKey: .timing)
        
        try container.encodeIfPresent(recurrence, forKey: .recurrence)
        try container.encodeIfPresent(detachedFrom, forKey: .detachedFrom)
        
        // omitted when non recurrant
        if !excludedOccurrences.isEmpty {
            try container.encode(excludedOccurrences, forKey: .excludedOccurrences)
            
        }
        
        try container.encodeIfPresent(isRecurring, forKey: .isRecurring)
        try container.encodeIfPresent(recurranceRate, forKey: .recurranceRate)
        try container.encodeIfPresent(recurringTimes, forKey: .recurringTimes)
        
        try container.encodeIfPresent(isCopy, forKey: .isCopy)
        try container.encodeIfPresent(copyOfEventWithID, forKey: .copyOfEventWithID)
        try container.encodeIfPresent(copyNumber, forKey: .copyNumber)
        
        try container.encode(isFavourite, forKey: .isFavourite)
        try container.encode(isMuted, forKey: .isMuted)
        
        try container.encode(isPinned, forKey: .isPinned)
        
        try container.encode(id, forKey: .id)
        
    }
}

private struct FailableEvent: Decodable {
    let event: Event?
    
    init(from decoder: Decoder) throws {
        event = try? Event(from: decoder)
        
    }
}

extension Event {
    static func decodeList(from data: Data) throws -> [Event] {
        let failableEvents = try JSONDecoder().decode([FailableEvent].self, from: data)
        let events = failableEvents.compactMap { $0.event }
        
        if events.count < failableEvents.count {
            print("\(failableEvents.count - events.count) of \(failableEvents.count) could not be decoded!!")
            
        }
        
        if events.isEmpty && !failableEvents.isEmpty {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No events could be decoded"))
            
        }
        
        return events
        
    }
}

