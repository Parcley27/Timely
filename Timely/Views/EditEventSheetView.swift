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
    @State var editedEndDateAndTime: Date = Date()
    @State var editedFavourite: Bool = false
    @State var editedMute: Bool = false
    
    var timesAfterStart: ClosedRange<Date> {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: editedDateAndTime)
        let startDate = calendar.date(from: startComponents)!
        
        let endComponents = DateComponents(year: 10000, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let endDate = calendar.date(from: endComponents)!
        
        return startDate...endDate
        
    }
    
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
                        DatePicker("Start Time", selection: $editedDateAndTime, displayedComponents: [.hourAndMinute, .date])
                            //.datePickerStyle(.compact)
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                        DatePicker("End Time", selection: $editedEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                        
                        //DatePicker("End Time", selection: $formEndDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute])
                        // DEBUG - Display date information
                        //Text("\(formatTime(inputDate: formDateAndTime))")
                        
                    }
                    .onAppear() {
                        editedDateAndTime = data[event].dateAndTime
                        editedEndDateAndTime = data[event].endDateAndTime ?? data[event].dateAndTime
                        
                    }
                    .onChange(of: editedDateAndTime) { _ in
                        if editedDateAndTime.timeIntervalSinceNow > editedEndDateAndTime.timeIntervalSinceNow {
                            editedEndDateAndTime = editedDateAndTime.addingTimeInterval(60 * 60)
                            
                        }
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
                        data[event].endDateAndTime = editedEndDateAndTime
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
