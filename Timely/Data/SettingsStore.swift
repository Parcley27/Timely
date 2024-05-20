//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation
import SwiftUI

@MainActor
class SettingsStore: ObservableObject {
    @Published var settings: [Settings] = []
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("settings.data")
    }
    
    func load() async throws {
        let task = Task<[Settings], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            
            let loadedEvents = try JSONDecoder().decode([Settings].self, from: data)
            return loadedEvents
        }
        
        let settings = try await task.value
        self.settings = settings
    }
    
    func save(settings: [Settings]) async throws {
        let task = Task {
            let data = try JSONEncoder().encode(settings)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}
