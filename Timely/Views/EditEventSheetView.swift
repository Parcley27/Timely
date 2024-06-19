//
//  EditEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-01-26.
//

import SwiftUI

struct EditEventSheetView: View {
    @Binding var data: [Event]
    let event: Int
        
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
                        TextField(data[event].name ?? "Name", text: $editedName)
                            .focused($isTextFieldFocused)
                            .onAppear() {
                                isTextFieldFocused = true
                                editedName = data[event].name ?? "Name"
                                
                            }
                        
                        TextField(data[event].emoji ?? "📅", text: $editedEmoji)
                            .onAppear() {
                                editedEmoji = data[event].emoji ?? "📅"
                                
                            }
                            .opacity(editedEmoji == "" ? 0.5: 1.0)
                    }
                    
                    Section("Details") {
                        ZStack {
                            HStack {
                                Text("Description")
                                    .foregroundStyle(.quaternary)
                                    .opacity(editedDescription == "" ? 100 : 0)
                                    .padding(.leading, 4)
                                Spacer()
                                
                            }
                            
                            TextEditor(text: $editedDescription)
                            
                        }
                    }
                    .onAppear() {
                        editedDescription = data[event].description ?? ""
                        
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Date and Time", selection: $editedDateAndTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                    }
                    .onAppear() {
                        editedDateAndTime = data[event].dateAndTime
                        
                    }
                    
                    Section("Importance") {
                        Toggle("Favourite", isOn: $editedFavourite)
                            .onAppear() {
                                editedFavourite = data[event].isFavourite
                                
                            }
                        
                        Toggle("Muted", isOn: $editedMute)
                            .onAppear() {
                                editedMute = data[event].isMuted
                                
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
                        data[event].name = editedName
                        
                        if editedEmoji == "" {
                            data[event].emoji = "📅"
                            
                        } else {
                            editedEmoji = String(editedEmoji.prefix(1))
                            data[event].emoji = editedEmoji
                            
                        }
                        
                        if editedDescription != "" {
                            data[event].description = editedDescription
                            
                        }
                        
                        data[event].dateAndTime = editedDateAndTime
                        data[event].isFavourite = editedFavourite
                        data[event].isMuted = editedMute
                        
                        data.sort(by: { $0.dateAndTime < $1.dateAndTime })
                        
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [data[event].id.uuidString])
                        
                        Task {
                            do {
                                try await EventStore().save(events: data)
                                
                                EventStore().scheduleNotifications(for: data[event])
                                
                            } catch {
                                fatalError(error.localizedDescription)
                                
                            }
                        }
                        
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
        
        let previewEvents = Binding.constant(previewData.events)
        
        return EditEventSheetView(data: previewEvents, event: 0)
        
    }
}
