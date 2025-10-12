//
//  EventData Extension.swift
//  Timely
//
//  Created by Pierce Oxley on 12/10/25.
//

import Foundation

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
            
            let timeAgoFormat = NSLocalizedString("%@ ago", comment: "")
            
            return String(format: timeAgoFormat, formattedString)
            
        } else {
            return NSLocalizedString("Time Unknown", comment: "")
            
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
            if event.hasPassed {
                count += 1
                
            }
        }
        
        return count
        
    }
    
    func indexFor(_ event: Event) ->  Double {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            return Double(index)
            
        }
        
        return 0.0
        
    }
}

