//
//  SettingsStore.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import Foundation

@MainActor
class SettingsStore: ObservableObject {
    @Published var showBadge: Bool = true {
        didSet {
            UserDefaults.standard.set(showBadge, forKey: "showBadge")
        }
    }
    
    @Published var deletePassedEvents: Bool = true {
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
        self.showBadge = UserDefaults.standard.bool(forKey: "showBadge")
        self.deletePassedEvents = UserDefaults.standard.bool(forKey: "deletePassedEvents")
        //self.deletePassedEvents = UserDefaults.standard.string(forKey: "userName") ?? ""
    }
}
