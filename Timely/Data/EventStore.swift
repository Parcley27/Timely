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
    
    func removeExpiredEvents() {
        let oneHourInSeconds = 60 * 60
        events.removeAll { event in
            event.hasExpired(maxTime: oneHourInSeconds)
            
        }
        
        Task {
            do {
                try await save(events: events)
                
            } catch {
                fatalError(error.localizedDescription)
                
            }
        }
    }
    
    func scheduleNotificationsForAllEvents() {
        for event in events {
            scheduleNotification(for: event)
            
        }
    }
    
    func scheduleNotification(for event: Event) {
        // Clear any existing notifications for the event
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id.uuidString])
        
        if !event.isMuted {
            let triggerDate = Calendar.current.date(byAdding: .minute, value: -5, to: event.dateAndTime)
            
            guard let triggerDate = triggerDate else { return }
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            
            let content = UNMutableNotificationContent()
            content.title = "\(event.name!)  \(event.emoji!)"
            content.body = "Your event is starting in 5 minutes"
            content.sound = .default
            
            if event.isFavourite {
                content.interruptionLevel = .timeSensitive
                
            }
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
            
            // Schedule notification for the event
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                    
                }
            }
        }
    }
}
