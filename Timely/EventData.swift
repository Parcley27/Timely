//
//  EventData.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-13.
//

import SwiftUI

class EventData : ObservableObject {
    /*
    @Published var events = [
        Event(name: "Pierce", date: "2007/12/31", time: "12:41", emoji: "🐎"),
        Event(name: "Wade", date: "2009/11/13", emoji: "☠️"),
        Event(name: "Guy", date: "2011/08/04", time: "23:59",  emoji: "🌲"),
        Event(name: "Dad", date: "1971/01/24", time: "15:20"),
        Event(name: "Mom", date: "1975/10/05", emoji: "👩‍⚖️")
    ]
     */
    
    @Published var events = [
        Event(name: "Pierce", emoji: "🐎"),
        Event(name: "Wade", emoji: "🔫"),
        Event(name: "Guy", emoji: "🌲")
    ]
}

struct Event : Identifiable {
    var name: String? = "Event Name"
    var emoji: String? = "📅"
    var description: String? = "Event Description"
    
    var dateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        return currentDate.addingTimeInterval(oneDayInSeconds)
    }()
    
    
    var isFavourite: Bool? = false
    var isMuted: Bool? = false
    
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
    
    func timeUntil(inputDate: Date) -> String {
        let timeInterval = inputDate.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.year, .day, .hour, .minute, .second]
        
        if let formattedString = formatter.string(from: timeInterval) {
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
    
    func indexFor(_ event: Event) ->  Double {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            return Double(index)
        }
        return 0.0
    }
}



/*
struct EventData: PreviewProvider {
    static var previews: some View {
        EventData()
    }
}
*/
