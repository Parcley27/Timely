//
//  TimelyApp.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//

// Change color with system theme
//
//@Environment(\.colorScheme) var colorScheme
//
//.foregroundColor(colorScheme == .dark ? .white : .black)

import SwiftUI
import SwiftData

@main
struct TimelyApp: App {
    @StateObject var eventList = EventData()
    
    /*
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    */

    var body: some Scene {
        WindowGroup {
            TabView {
                /*
                ContentView()
                    //.badge()
                    .tabItem {
                        Label("ContentView", systemImage: "folder.fill")
                    }
                 */
                
                EventListView()
                    //.badge()
                    .tabItem {
                        Label("Events", systemImage: "calendar")
                    }
                
                    .environmentObject(eventList)
                
                Settings()
                    //.badge()
                    .tabItem {
                        Label("Settings", systemImage: "pencil")
                    }
                
                    .environmentObject(eventList)
            }
        }
        //.modelContainer(sharedModelContainer)
    }
}
