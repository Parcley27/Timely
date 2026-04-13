//
//  SharedEventStore.swift
//  Timely
//
//  Created by Pierce Oxley on 12/4/26.
//

import Foundation

struct SharedEventStore {
    static let appGroupID = "group.com.PierceOxley.Timely"
    static let filename = "sharedEvents.json"

    private static func fileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(filename)

    }

    static func save(events: [Event]) {
        guard let url = fileURL() else {
            print("SharedEventStore: could not resolve app group container URL")
            return

        }

        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: url, options: .atomic)
            print("SharedEventStore: saved \(events.count) events to \(url)")

        } catch {
            print("SharedEventStore: save failed — \(error)")

        }
    }

    static func load() -> [Event] {
        guard let url = fileURL() else {
            print("SharedEventStore: could not resolve app group container URL")
            return []

        }

        do {
            let data = try Data(contentsOf: url)
            let events = try JSONDecoder().decode([Event].self, from: data)
            print("SharedEventStore: loaded \(events.count) events")
            return events

        } catch {
            print("SharedEventStore: load failed — \(error)")
            return []

        }
    }
}
