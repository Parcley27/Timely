//
//  ContentView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-06-14.
//

import SwiftUI
import SwiftData

/*
 struct ContentView: View {
 @Environment(\.modelContainer) private var modelContainer
 @State private var events: [Event] = []
 
 var body: some View {
 // Use events obtained from SwiftData
 List(events) { event in
 Text(event.name ?? "Event Name")
 }
 .onAppear {
 // Fetch events from SwiftData
 events = try! modelContainer.get(Event.self).fetchAll()
 }
 }
 }
 
 #Preview {
 ContentView()
 .modelContainer(for: Event.self, inMemory: true)
 }
 
 */
