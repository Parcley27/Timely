//
//  NewEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-18.
//

import SwiftUI

struct NewEventSheetView: View {
    @EnvironmentObject var data: EventData

    @Environment(\.dismiss) var dismiss
    
    @State private var formName: String = ""
    @State private var formEmoji: String = ""
    @State private var formDateAndTime: Date = Date()
    @State private var formFavourited: Bool = false
    @State private var formMutedL: Bool = true

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("About") {
                        TextField("Event Name", text: $formName)

                        TextField("Event Emoji (Optional)", text: $formEmoji)
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Event Date", selection: $formDateAndTime, displayedComponents: [.date])
                        DatePicker("Event Time", selection: $formDateAndTime, displayedComponents: [.hourAndMinute])
                        Text("\(formDateAndTime)")
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
                        // Chnage to add new data to EventData
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("Events", displayMode: .inline)
        }
    }
    
    /*
        NavigationView {
            VStack {
                Button("Done") {
                    dismiss()
                }
                
                List() {
                    Text("Example Text")
                    Text("Example Text 2")
                    //Text(data)
                }
                
                Button {
                    let newEvent = Event(name: "New Event", emoji: "📅")
                    data.events.append(newEvent)
                } label: {
                    Label("New", systemImage: "plus")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("test")
            }
        }
    }
     */
}

struct NewEventSheetView_Previews: PreviewProvider {
    static var previews: some View {
        NewEventSheetView()
    }
}
