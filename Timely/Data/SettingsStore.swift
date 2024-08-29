//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation

class SettingsStore: ObservableObject {
    var showBadge: Bool {
        didSet {
            UserDefaults.standard.set(showBadge, forKey: "showBadge")
            
        }
    }
    
    // deletePassedEvents
    var removePassedEvents: Bool {
        didSet {
            UserDefaults.standard.set(removePassedEvents, forKey: "removePassedEvents")
            
        }
    }
    
    // archiveOldEvents
    var keepEventHistory: Bool {
        didSet {
            UserDefaults.standard.set(keepEventHistory, forKey: "keepEventHistory")
            
        }
    }
    
    var quickAdd: Bool {
        didSet {
            UserDefaults.standard.set(quickAdd, forKey: "quickAdd")
            
        }
    }
    
    var listTinting: Bool {
        didSet {
            UserDefaults.standard.set(listTinting, forKey: "listTinting")
            
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
        self.quickAdd = UserDefaults.standard.object(forKey: "quickAdd") as? Bool ?? false
        self.listTinting = UserDefaults.standard.object(forKey: "listTinting") as? Bool ?? true
        //self.stringData = UserDefaults.standard.object(forKey: "stringData") as? String ?? ""
        
    }
}
