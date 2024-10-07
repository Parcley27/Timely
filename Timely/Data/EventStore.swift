//
//  EventStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-02-15.
//

import Foundation
import SwiftUI

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    
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
                /*
                if let jsonString = String(data: data, encoding: .utf8) {
                    //print("Loaded JSON from iCloud: \(jsonString)")
                    
                }
                */
                
                print("Loaded JSON from iCloud")
                
                let loadedEvents = try JSONDecoder().decode([Event].self, from: data)
                
                DispatchQueue.main.async {
                    self.events = loadedEvents
                    
                }
                
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
        //print(events)
        
        let store = NSUbiquitousKeyValueStore.default
        
        do {
            // Encode the events array to JSON
            let data = try JSONEncoder().encode(events)
            
            // Print JSON string before saving
            if let _ = String(data: data, encoding: .utf8) {
                //print("JSON to be saved to iCloud: \(jsonString.truncatingToLength(100))")
                print("JSON string valid")
                
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
            //print(events)
            let data = try JSONEncoder().encode(events)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
            
        }
        
        _ = try await task.value
        
        saveToiCloud(events: events)
        
        scheduleNotificationsForAllEvents()
        
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
        removeAllNotifications()
        
        for event in events.filter({ !$0.hasStarted }) {
            print("Writing notification for \(event.name!)")
            
            scheduleNotifications(for: event)
            
        }
    }
    
    func scheduleNotifications(for event: Event) {
        let standardTimes: [Int] = [0, 15]
        let favouriteTimes: [Int] = [0, 15, 60]
        let allDayTime: Int = 360
        
        if !event.isMuted {
            if event.isAllDay ?? false {
                addNotification(for: event, time: allDayTime)
                
            } else {
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
            
        } else if time < 360 {
            // Starting in \(time/60) hours, at \(eventTime).
            content.body = String(format: NSLocalizedString("Starting in %1$@ hours, at %2$@.", comment: ""), String(format: "%.1f", Double(time) / 60.0), eventTime)
            
        } else {
            content.body = String(format: NSLocalizedString("All Day Tomorrow", comment: ""))
            
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
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("Removing notifications")
        
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
