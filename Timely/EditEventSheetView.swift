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
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("Event Name") {
                        Text(event.name ?? "Event Name")
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
                    Button ("Done") {
                        // Update event data
                        
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
