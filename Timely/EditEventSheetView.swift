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
        Text(event.name ?? "Event Name")
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
