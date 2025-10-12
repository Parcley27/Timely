//
//  TimelyApp.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//


import SwiftUI

import SwiftUI

@main
struct TimelyApp: App {
    @StateObject var eventStore = EventStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(eventStore)
            
        }
    }
}
