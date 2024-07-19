//
//  EventStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-02-15.
//

import Foundation
import SwiftUI

@MainActor
class EventStore: ObservableObject {
    @Published var events: [Event] = []
    
    var allNotificationTimes: [Int] = [0, 15, 60]
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, 
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("events.data")
    }
    
    func load() async throws {
        let task = Task<[Event], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
                
            }
            
            let loadedEvents = try JSONDecoder().decode([Event].self, from: data)
            return loadedEvents
        }
        
        let events = try await task.value
        self.events = events
    }
    
    func save(events: [Event]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(events)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
            
        }
        _ = try await task.value
    }
    
    func deleteExpiredEvents() {
        //let oneHourInSeconds = 60 * 60
        events.removeAll { event in
            event.hasExpired()
            
        }
        
        Task {
            do {
                try await save(events: events)
                
            } catch {
                fatalError(error.localizedDescription)
                
            }
        }
    }
    
    func formatTimeForNotification(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
        
    }
    
    func scheduleNotificationsForAllEvents() {
        for event in events {
            scheduleNotifications(for: event)
            
        }
    }
    
    func scheduleNotifications(for event: Event) {
        // Clear any existing notifications
        removeNotifications(for: event)
        
        let standardTimes: [Int] = [0, 15]
        let favouriteTimes: [Int] = [0, 15, 60]
        
        if !event.isMuted && !event.hasExpired() {
            if event.isFavourite {
                for time in favouriteTimes {
                    addNotification(for: event, time: time)
                    
                }
            } else {
                for time in standardTimes {
                    addNotification(for: event, time: time)
                    
                }
            }
        }
    }
    
    func addNotification(for event: Event, time: Int) {
        let notificationIdentifier = "\(event.id.uuidString) \(time) minutes"
        
        let content = UNMutableNotificationContent()
        content.title = "\(event.name!) • \(event.emoji!)"
        content.sound = .default
        
        let eventTime = formatTimeForNotification(from: event.dateAndTime)
        
        if time == 0 {
            content.body = "Starting now!"
            
        } else if time < 60 {
            content.body = "Starting in \(time) minutes, at \(eventTime)."
            
        } else if time == 60 {
            content.body = "Starting in 1 hour, at \(eventTime)"
            
        } else if time > 60 {
            content.body = "Starting in \(time/60) hours, at \(eventTime)."
            
        }
        
        if event.isFavourite && time <= 15 {
            content.interruptionLevel = .timeSensitive
            
        }
        
        content.threadIdentifier = event.id.uuidString
        
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -time, to: event.dateAndTime)
        guard let triggerDate = triggerDate else { return }
        
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
                
            }
        }
    }
    
    func removeNotifications(for event: Event) {
        for time in allNotificationTimes {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(event.id.uuidString) \(time) minutes"])
            
        }
    }
}
