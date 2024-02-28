//
//  EventData.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI

class EventData : ObservableObject {
    @Published var events = [
        Event(name: "Riding Lesson", emoji: "🐎"),
        Event(name: "Lazer Tag", emoji: "🔫"),
        Event(name: "Nature Walk", emoji: "🌲")
    ]
}

struct Event : Identifiable, Codable {
    var name: String? = "Event Name"
    var emoji: String? = "📅"
    var description: String?
    
    var dateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        return currentDate.addingTimeInterval(oneDayInSeconds)
    }()
    
    var dateString: String? {
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "dd MMM, yyyy 'at' h:mm a"
        // Adapts to user settings
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let formattedDate = dateFormatter.string(from: dateAndTime)

        return formattedDate
    }
    
    var timeUntil: String {
        let timeInterval = dateAndTime.timeIntervalSinceNow
                
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.year, .day, .hour, .minute, .second]
                
        if let formattedString = formatter.string(from: timeInterval) {
            return formattedString
        } else {
            return "Time Until Date"
        }
    }
    
    var isFavourite: Bool = false
    var isMuted: Bool = false
    
    var id = UUID()
}


// Should be hidden probably
extension EventData {
    func removeEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            events.remove(at: index)
        }
    }
    
    func updateEventName(event: Event, newName: String) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            events[index].name = newName
        }
    }
    
    func toggleFavouriteEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            if events[index].isFavourite == true {
                events[index].isFavourite = false
            } else {
                events[index].isFavourite = true
            }
        }
    }
    
    func toggleMutedEvent(event: Event) {
        if let index = events.firstIndex(where: {$0.id == event.id}) {
            if events[index].isMuted == true {
                events[index].isMuted = false
            } else {
                events[index].isMuted = true
            }
        }
    }
    
    func timeUntil(inputDate: Date, format: String? = "Full Date") -> String {        
        let timeInterval = inputDate.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        
        if format == "Full Date" {
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.year, .day, .hour, .minute, .second]
        }
        
        if format == "Seconds" {
            formatter.unitsStyle = .positional
            formatter.allowedUnits = [.second]
        }
        
        if var formattedString = formatter.string(from: timeInterval) {
            formattedString = formattedString.replacingOccurrences(of: ",", with: "")
            return formattedString
        } else {
            return "Time unknown"
        }
    }
    
    func dateDisplayString(event: Event) -> String {
        let dateToDisplay = event.dateAndTime
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateString = dateFormatter.string(from: dateToDisplay)
        
        if dateString != "" {
            return dateString
        } else {
            return "Date unknown"
        }
    }
    
    func passedEvents() -> Int {
        var count = 0
        
        for event in events {
            if event.timeUntil.prefix(1) == "-" {
                count += 1
            }
        }
        
        return count
    }
    
    /*
    func sortEvents(filter: String? = "Date Ascending") {
        if filter == "Date Ascending" {
            for event in events {
                // Sort by lowest date -> highest date
            }
        }
    }
    */
    
    func indexFor(_ event: Event) ->  Double {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            return Double(index)
        }
        return 0.0
    }
}
