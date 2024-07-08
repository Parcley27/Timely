//
//  NewEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-18.
//

import SwiftUI
import Foundation

struct NewEventSheetView: View {
    @Binding var data: [Event]
    @StateObject private var store = EventStore()
    @StateObject private var preferences = SettingsStore()
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isTextFieldFocused: Bool
        
    @State private var formName: String = ""
    @State private var formEmoji: String = ""
    @State private var formDescription: String = ""
    @State private var formDateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        let oneHourInSeconds: TimeInterval = 60 * 60
        
        //return currentDate.addingTimeInterval(oneDayInSeconds)
        return currentDate.addingTimeInterval(oneHourInSeconds)

    }()
    @State private var formFavourited: Bool = false
    @State private var formMuted: Bool = false
    
    private func formatTime(inputDate: Date) -> Date {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: inputDate)
        
        if let formattedDate = calendar.date(from: components) {
            return formattedDate
            
        } else {
            return inputDate
            
        }
    }
    
    private func createEvent() {
        if formEmoji.isEmpty {
            formEmoji = "📅"
            
        } else {
            formEmoji = String(formEmoji.prefix(1))
            
        }
        
        let newEvent = Event (
            name: formName,
            emoji: formEmoji,
            description: (formDescription != "" ? formDescription : nil),
            dateAndTime: formDateAndTime,
            isFavourite: formFavourited,
            isMuted: formMuted
            
        )
                
        data.append(newEvent)
        data.sort(by: { $0.dateAndTime < $1.dateAndTime })
        
        Task {
            do {
                try await store.save(events: data)
                store.scheduleNotifications(for: newEvent)

                
            } catch {
                fatalError(error.localizedDescription)
                
            }
        }
        
        print("Saving event: \(newEvent)")
        
        for event in data {
            print(event)
            
        }
    }
    
    func askForNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("Notifications accepted")
                
            } else if let error {
                print(error.localizedDescription)
                
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section("About") {
                        TextField("Name", text: $formName)
                            .focused($isTextFieldFocused)
                            .onAppear {
                                isTextFieldFocused = true
                                
                            }
                        
                        TextField("Emoji", text: $formEmoji)
                        
                    }
                    
                    if !preferences.quickAdd {
                        Section("Details") {
                            ZStack {
                                HStack {
                                    Text("Description")
                                        .foregroundStyle(.quaternary)
                                        .opacity(formDescription == "" ? 100 : 0)
                                        .padding(.leading, 4)
                                    Spacer()
                                    
                                }
                                
                            }
                            
                            TextEditor(text: $formDescription)
                                
                        }
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Date and Time", selection: $formDateAndTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(GraphicalDatePickerStyle())
                        // DEBUG - Display date information
                        //Text("\(formatTime(inputDate: formDateAndTime))")
                        
                    }
                    
                    if !preferences.quickAdd {
                        Section("Importance") {
                            Toggle("Favourite", isOn: $formFavourited)
                            Toggle("Muted", isOn: $formMuted)
                            
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
                    Button ("Save") {
                        createEvent()
                        
                        askForNotifications()
                        
                        dismiss()
                        
                    }
                    .disabled(formName.isEmpty)
                }
            }
            .navigationBarTitle("New Event", displayMode: .inline)
        }
    }
}

struct NewEventSheetView_Previews: PreviewProvider {
    static var previews: some View {
        @StateObject var eventList = EventStore()
        
        return NewEventSheetView(data: $eventList.events)
        
    }
}
