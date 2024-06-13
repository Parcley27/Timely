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
    
    // deletePassedEvents
    @Published var removePassedEvents: Bool {
        didSet {
            UserDefaults.standard.set(removePassedEvents, forKey: "removePassedEvents")
            
        }
    }
    
    // archiveOldEvents
    @Published var keepEventHistory: Bool {
        didSet {
            UserDefaults.standard.set(keepEventHistory, forKey: "keepEventHistory")
            
        }
    }
    
    /*
    @Published var stringData: String {
        didSet {
            UserDefaults.standard.set(stringData, forKey: "stringData")
     
        }
    }
     */
    
    init() {
        self.showBadge = UserDefaults.standard.object(forKey: "showBadge") as? Bool ?? true
        self.removePassedEvents = UserDefaults.standard.object(forKey: "removePassedEvents") as? Bool ?? true
        self.keepEventHistory = UserDefaults.standard.object(forKey: "keepEventHistory") as? Bool ?? true
        //self.stringData = UserDefaults.standard.object(forKey: "stringData") as? String ?? ""
        
    }
}
