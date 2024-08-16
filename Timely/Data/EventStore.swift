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
    
    func getAllEvents() -> [Event] {
        return events
        
    }
        
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
            //print(events)
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
