//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation
import Combine

class SettingsStore: ObservableObject {
    @Published var showBadge: Bool {
        didSet {
            saveToiCloud("showBadge", value: showBadge)
            
        }
    }
    
    // deletePassedEvents
    @Published var removePassedEvents: Bool {
        didSet {
            saveToiCloud("removePassedEvents", value: removePassedEvents)
            
        }
    }
    
    // archiveOldEvents
    @Published var keepEventHistory: Bool {
        didSet {
            saveToiCloud("keepEventHistory", value: keepEventHistory)
            
        }
    }
    
    @Published var quickAdd: Bool {
        didSet {
            saveToiCloud("quickAdd", value: quickAdd)
            
        }
    }
    
    @Published var listTinting: Bool {
        didSet {
            saveToiCloud("listTinting", value: listTinting)
            
        }
    }
    
    /*
    @Published var stringData: String {
        didSet {
            UserDefaults.standard.set(stringData, forKey: "stringData")
     
        }
    }
     */
    
    private var iCloudStore: NSUbiquitousKeyValueStore
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.iCloudStore = NSUbiquitousKeyValueStore.default
        self.showBadge = iCloudStore.object(forKey: "showBadge") as? Bool ?? true
        self.removePassedEvents = iCloudStore.object(forKey: "removePassedEvents") as? Bool ?? true
        self.keepEventHistory = iCloudStore.object(forKey: "keepEventHistory") as? Bool ?? true
        self.quickAdd = iCloudStore.object(forKey: "quickAdd") as? Bool ?? false
        // Change to true with update v3.0
        self.listTinting = iCloudStore.object(forKey: "listTinting") as? Bool ?? false
        
        // Sync changes from iCloud to the local state
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification)
            .sink { _ in
                self.showBadge = self.iCloudStore.object(forKey: "showBadge") as? Bool ?? true
                self.removePassedEvents = self.iCloudStore.object(forKey: "removePassedEvents") as? Bool ?? true
                self.keepEventHistory = self.iCloudStore.object(forKey: "keepEventHistory") as? Bool ?? true
                self.quickAdd = self.iCloudStore.object(forKey: "quickAdd") as? Bool ?? false
                // Change to true with update v3.0
                self.listTinting = self.iCloudStore.object(forKey: "listTinting") as? Bool ?? false
                
            }
            .store(in: &cancellables)
    }
    
    private func saveToiCloud(_ key: String, value: Any) {
        iCloudStore.set(value, forKey: key)
        iCloudStore.synchronize()
        
    }
}
