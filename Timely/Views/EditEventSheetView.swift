//
//  EditEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-01-26.
//

import SwiftUI

struct EditEventSheetView: View {
    @Binding var data: [Event]
    @Binding var event: Event
    
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.dismiss) var dismiss
                
    @State var editedName: String = ""
    @State var editedEmoji: String = ""
    @State var editedDescription: String = ""
    @State var editedDateAndTime: Date = Date()
    @State var editedFavourite: Bool = false
    @State var editedMute: Bool = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("About") {
                        TextField(event.name ?? "Event Name", text: $editedName)
                            .focused($isTextFieldFocused)
                            .onAppear() {
                                // Set the focus to the text field when the view appears
                                isTextFieldFocused = true
                                editedName = event.name ?? "Event Name"
                            }
                        
                        TextField(event.emoji ?? "📅", text: $editedEmoji)
                            .onAppear() {
                                editedEmoji = event.emoji ?? "📅"
                            }
                            .onChange(of: editedEmoji) { _ in
                                editedEmoji = String(editedEmoji.prefix(1))

                            }
                            .opacity(editedEmoji == "" ? 0.5: 1.0)
                    }
                    
                    Section("Details") {
                        TextField(event.description ?? "Event Description", text: $editedDescription)
                            .onAppear() {
                                editedDescription = event.description ?? ""
                            }
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Date", selection: $editedDateAndTime, displayedComponents: [.date])
                        DatePicker("Time", selection: $editedDateAndTime, displayedComponents: [.hourAndMinute])
                    }
                    .onAppear() {
                        editedDateAndTime = event.dateAndTime
                    }
                    
                    Section("More") {
                        Toggle("Favourite", isOn: $editedFavourite)
                            .onAppear() {
                                editedFavourite = event.isFavourite
                            }
                        
                        Toggle("Mute", isOn: $editedMute)
                            .onAppear() {
                                editedMute = event.isMuted
                            }
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
                    Button("Save") {
                        // Update event data
                        
                        event.name = editedName
                        
                        if editedEmoji == "" {
                            event.emoji = "📅"
                        } else {
                            event.emoji = editedEmoji
                        }
                        
                        if editedDescription != "" {
                            event.description = editedDescription
                        }
                        
                        event.dateAndTime = editedDateAndTime
                        event.isFavourite = editedFavourite
                        event.isMuted = editedMute
                        
                        print(event)
                        
                        dismiss()
                    }
                    .disabled(editedName == "")
                }
            }
            .navigationBarTitle("Edit Event", displayMode: .inline)
        }
    }
}

struct EditEventSheetViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
        ]

        // Create a binding to the events array in previewData
        let previewEvents = Binding.constant(previewData.events)

        return EditEventSheetView(data: previewEvents, event: Binding.constant(previewData.events[0]))
    }
}
