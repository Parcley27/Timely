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
    var endDateAndTime: Date?
    var isOnDates: [Date] {
        var dates: [Date] = []
        var currentDate = dateAndTime
        
        let oneDayInSeconds: Double = 24 * 60 * 60
        
        while currentDate <= endDateAndTime ?? dateAndTime {
            dates.append(currentDate)
            
            currentDate = currentDate.addingTimeInterval(oneDayInSeconds)
            
        }
        
        return dates
        
    }
    
    var dateString: String? {
        let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "dd MMM, yyyy 'at' h:mm a"
        // Auto adapts to user system settings
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var formattedDate = "Event Date and Time String"
        
        func isBeforeOrAfter12(date: Date) -> String {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            
            if hour < 12 {
                return "AM"
                
            } else {
                return "PM"
                
            }
        }
        
        if endDateAndTime != nil {
            if dateAndTime == endDateAndTime! {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
                
                formattedDate = dateFormatter.string(from: dateAndTime)
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .day) {
                if isBeforeOrAfter12(date: dateAndTime) == isBeforeOrAfter12(date: endDateAndTime!) {
                    dateFormatter.dateFormat = "h:mm"
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, MMMM d, yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                } else {
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a", comment: "")
                    let firstTime = dateFormatter.string(from: dateAndTime)
                    
                    dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEE, MMMM d, yyyy", comment: "")
                    let secondTime = dateFormatter.string(from: endDateAndTime!)
                    
                    // "\(firstTime) to \(secondTime)"
                    let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                    formattedDate = String(format: stringFormat, firstTime, secondTime)
                    
                }
                
            } else if Calendar.current.isDate(dateAndTime, equalTo: endDateAndTime!, toGranularity: .year) {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d", comment: "")
                let firstTime = dateFormatter.string(from: dateAndTime)
                
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to %2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            } else {
                dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMM d, yyyy", comment: "")
                
                let firstTime = dateFormatter.string(from: dateAndTime)
                let secondTime = dateFormatter.string(from: endDateAndTime!)
                
                // "\(firstTime) to\n\(secondTime)"
                let stringFormat = NSLocalizedString("%1$@ to\n%2$@", comment: "")
                formattedDate = String(format: stringFormat, firstTime, secondTime)
                
            }
            
        } else {
            dateFormatter.dateFormat = NSLocalizedString("h:mm a 'on' EEEE, MMMM d, yyyy", comment: "")
            
            formattedDate = dateFormatter.string(from: dateAndTime)
            
        }
        
        return formattedDate
        
    }
    
    var timeUntil: String {
        let timeIntervalToStart = dateAndTime.timeIntervalSinceNow
        let timeIntervalToEnd = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        
        let oneDayInSeconds = 86000.0
        let oneHourInSeconds = 3600.0
        
        if timeIntervalToStart > oneDayInSeconds || timeIntervalToEnd < -oneDayInSeconds {
            formatter.allowedUnits = [.year, .month, .day, .hour]
            
        } else if timeIntervalToStart > oneHourInSeconds || timeIntervalToEnd < -oneHourInSeconds {
            formatter.allowedUnits = [.day, .hour, .minute]
            
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
           
        /*
        if let formattedString = formatter.string(from: timeInterval) {
            return formattedString
            
        } else {
            return "Time Until Date"
            
        }
         */
        
        //if hasStarted == false {
            //return formatter.string(from: timeIntervalToStart)!
        
        if hasPassed {
            if var timePastString = formatter.string(from: timeIntervalToEnd) {
                timePastString.remove(at: timePastString.startIndex)
                
                let timeAgoFormat = NSLocalizedString("%@ ago", comment: "")
                return String(format: timeAgoFormat, timePastString)
                
            } else {
                return NSLocalizedString("Time Unknown", comment: "")
                
            }
            
        } else if hasStarted && !hasPassed {
            return NSLocalizedString("Right Now", comment: "")
            
        } else {
            if let timeUntilString = formatter.string(from: timeIntervalToStart) {
                return timeUntilString
                
            } else {
                return NSLocalizedString("Time Unknown", comment: "")
                
            }
        }
    }
    
    var hasStarted: Bool {
        let timeInterval = dateAndTime.timeIntervalSinceNow
        
        if timeInterval <= 0.0 {
            return true
            
        } else {
            return false
            
        }
    }
    
    var hasPassed: Bool {
        let timeInterval = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        if timeInterval <= 0.0 {
            return true
            
        } else {
            return false
            
        }
    }
    
    // One hour in seconds
    func hasExpired(maxTime: Int = 3600) -> Bool {
        let timeInterval = endDateAndTime?.timeIntervalSinceNow ?? dateAndTime.timeIntervalSinceNow
        
        if timeInterval < -Double(maxTime) {
            return true
            
        } else {
            return false
            
        }
    }
    
    var isFavourite: Bool = false
    
    var isStandard: Bool {
        if !isFavourite && !isMuted {
            return true
            
        } else {
            return false
            
        }
    }
    
    var isMuted: Bool = false
    
    var id = UUID()
}

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
