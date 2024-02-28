//
//  EditEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-01-26.
//

import SwiftUI

struct EditEventSheetView: View {
    @EnvironmentObject var data: EventData
    
    @Environment(\.dismiss) var dismiss
    
    @State var event: Event
    
    @State private var editedName: String = ""
    
    init(event: Event) {
            _event = State(initialValue: event)
            _editedName = State(initialValue: event.name ?? "")
        }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Event Name") {
                        TextField(event.name ?? "Event Name", text: $editedName)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button ("Save") {
                        // Update event data
                        
                        event.name = editedName
                        
                        print(event)
                        
                        dismiss()
                    }
                }
            }
            .navigationBarTitle(event.name ?? "Edit Event", displayMode: .inline)
        }
    }
}

#Preview {
    let previewData = EventData()
    previewData.events = [
        Event(name: "Sample Event"),
    ]

    return EditEventSheetView(event: previewData.events[0])
        .environmentObject(previewData)
}
