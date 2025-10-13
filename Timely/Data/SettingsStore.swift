//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation

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
    
    @Published var quickAdd: Bool {
        didSet {
            UserDefaults.standard.set(quickAdd, forKey: "quickAdd")
            
        }
    }
    
    @Published var listTinting: Bool {
        didSet {
            UserDefaults.standard.set(listTinting, forKey: "listTinting")
            
        }
    }
    
    @Published var doiCloudSync: Bool {
        didSet {
            UserDefaults.standard.set(doiCloudSync, forKey: "doiCloudSync")
            
        }
    }
    
    @Published var useEmojiKeyboard: Bool {
        didSet {
            UserDefaults.standard.set(useEmojiKeyboard, forKey: "useEmojiKeyboard")
            
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
        self.doiCloudSync = UserDefaults.standard.object(forKey: "doiCloudSync") as? Bool ?? false
        self.useEmojiKeyboard = UserDefaults.standard.object(forKey: "useEmojiKeyboard") as? Bool ?? true
        //self.stringData = UserDefaults.standard.object(forKey: "stringData") as? String ?? ""
        
    }
}
