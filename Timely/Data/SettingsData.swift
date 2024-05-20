//
//  SettingsData.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-05-19.
//

import SwiftUI

struct Settings : Identifiable, Codable {
    var autoDelete: Bool? = false
    var showSeconds: Bool? = false
    var sendNotifications: Bool? = false
    
    var id = UUID()
    
}
