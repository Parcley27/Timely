//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation

class SettingsStore: ObservableObject {
    enum Defaults {
        static let showBadge = true
        static let removePassedEvents = true
        static let keepEventHistory = true
        static let quickAdd = false
        static let listTinting = true
        static let doiCloudSync = false
        static let useEmojiKeyboard = true
        static let useLegacyLayout = false
    
    }
    
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
    
    @Published var useLegacyLayout: Bool {
        didSet {
            UserDefaults.standard.set(useLegacyLayout, forKey: "useLegacyLayout")
            
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
        self.showBadge = UserDefaults.standard.object(forKey: "showBadge") as? Bool ?? Defaults.showBadge
        self.removePassedEvents = UserDefaults.standard.object(forKey: "removePassedEvents") as? Bool ?? Defaults.removePassedEvents
        self.keepEventHistory = UserDefaults.standard.object(forKey: "keepEventHistory") as? Bool ?? Defaults.keepEventHistory
        self.quickAdd = UserDefaults.standard.object(forKey: "quickAdd") as? Bool ?? Defaults.quickAdd
        self.listTinting = UserDefaults.standard.object(forKey: "listTinting") as? Bool ?? Defaults.listTinting
        self.doiCloudSync = UserDefaults.standard.object(forKey: "doiCloudSync") as? Bool ?? Defaults.doiCloudSync
        self.useEmojiKeyboard = UserDefaults.standard.object(forKey: "useEmojiKeyboard") as? Bool ?? Defaults.useEmojiKeyboard
        self.useLegacyLayout = UserDefaults.standard.object(forKey: "useLegacyLayout") as? Bool ?? Defaults.useLegacyLayout
        
        //self.stringData = UserDefaults.standard.object(forKey: "stringData") as? String ?? ""
        
    }
    
    func resetToDefaults() {
        self.showBadge = Defaults.showBadge
        self.removePassedEvents = Defaults.removePassedEvents
        self.keepEventHistory = Defaults.keepEventHistory
        self.quickAdd = Defaults.quickAdd
        self.listTinting = Defaults.listTinting
        self.doiCloudSync = Defaults.doiCloudSync
        self.useEmojiKeyboard = Defaults.useEmojiKeyboard
        self.useLegacyLayout = Defaults.useLegacyLayout
        
    }
}
