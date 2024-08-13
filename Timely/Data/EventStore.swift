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
    
    // Load from iCloud
    func loadFromiCloud() {
        let store = NSUbiquitousKeyValueStore.default
        
        if let data = store.data(forKey: "events") {
            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Loaded JSON from iCloud: \(jsonString)")
                    
                }
                
                let loadedEvents = try JSONDecoder().decode([Event].self, from: data)
                self.events = loadedEvents
                
            } catch {
                print("Failed to load events from iCloud: \(error)")
                
            }
            
        } else {
            print("No events found in iCloud, loading from local storage.")
            
            Task {
                do {
                    try await load()
                    
                } catch {
                    print("Failed to load events from local storage: \(error)")
                    
                }
            }
        }
    }
    
    // Save to iCloud
    func saveToiCloud(events: [Event]) {
        print("Saving to iCloud")
        print(events)
        
        let store = NSUbiquitousKeyValueStore.default
        
        do {
            // Encode the events array to JSON
            let data = try JSONEncoder().encode(events)
            
            // Print JSON string before saving
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON to be saved to iCloud: \(jsonString)")
                
            }
            
            // Store the encoded data in iCloud
            store.set(data, forKey: "events")
            store.synchronize()
            
        } catch {
            print("Failed to save events to iCloud: \(error.localizedDescription)")
            
        }
    }
    
    func load() async throws {
        print("Loading from local storage")
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
        print("Saving to local storage")
        
        let task = Task {
            print(events)
            let data = try JSONEncoder().encode(events)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
            
        }
        
        _ = try await task.value
        
        saveToiCloud(events: events)
        
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
            // Starting Now!
            content.body = NSLocalizedString("Starting Now!", comment: "")
            
        } else if time < 60 {
            // Starting in \(time) minutes, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in %1$@ minutes, at %2$@.", comment: ""), String(time), eventTime)
            
        } else if time == 60 {
            // Starting in 1 hour, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in 1 hour, at %@.", comment: ""), eventTime)
            
        } else if time > 60 {
            // Starting in \(time/60) hours, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in %1$@ hours, at %2$@.", comment: ""), String(format: "%.1f", Double(time) / 60.0), eventTime)
            
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
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ubiquitousKeyValueStoreDidChange),
                                               name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: NSUbiquitousKeyValueStore.default)
        loadFromiCloud()
    
    }
    
    @objc private func ubiquitousKeyValueStoreDidChange(notification: NSNotification) {
        loadFromiCloud() // Reload data from iCloud when it changes
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
    }
}
