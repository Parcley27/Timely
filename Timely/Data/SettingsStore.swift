//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation

@MainActor
class SettingsStore: ObservableObject {
    @Published var showBadge: Bool {
        didSet {
            UserDefaults.standard.set(showBadge, forKey: "showBadge")
            
        }
    }
    
    @Published var deletePassedEvents: Bool {
        didSet {
            UserDefaults.standard.set(deletePassedEvents, forKey: "deletePassedEvents")
            
        }
    }
    
    /*
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "userName")
        }
    }
     */
    
    init() {
        self.showBadge = UserDefaults.standard.object(forKey: "showBadge") as? Bool ?? true
        self.deletePassedEvents = UserDefaults.standard.object(forKey: "deletePassedEvents") as? Bool ?? true
    }
}
