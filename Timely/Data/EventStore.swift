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
}
