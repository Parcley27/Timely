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
    @State private var formEndDateAndTime: Date = {
        let currentDate = Date()
        let twoHoursInSeconds: TimeInterval = 2 * 60 * 60
        
        return currentDate.addingTimeInterval(twoHoursInSeconds)
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
    
    let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        let endComponents = DateComponents(year: 10000, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        
        return calendar.date(from:startComponents)! ... calendar.date(from:endComponents)!
        
    }()
    
    var timesAfterStart: ClosedRange<Date> {
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: formDateAndTime)
        let startDate = calendar.date(from: startComponents)!
        
        let endComponents = DateComponents(year: 10000, month: 12, day: 31, hour: 23, minute: 59, second: 59)
        let endDate = calendar.date(from: endComponents)!
        
        return startDate...endDate
        
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
            endDateAndTime: formEndDateAndTime,
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
                            .textInputAutocapitalization(.words)
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
                                
                                TextEditor(text: $formDescription)
                                    
                            }
                        }
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Start Time", selection: $formDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute, .date])
                            //.datePickerStyle(.compact)
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                        if !preferences.quickAdd {
                            DatePicker("End Time", selection: $formEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                            
                        }
                        
                        //DatePicker("End Time", selection: $formEndDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute])
                        // DEBUG - Display date information
                        //Text("\(formatTime(inputDate: formDateAndTime))")
                        
                    }
                    .onChange(of: formDateAndTime) { _ in
                        if formDateAndTime.timeIntervalSinceNow > formEndDateAndTime.timeIntervalSinceNow {
                            formEndDateAndTime = formDateAndTime.addingTimeInterval(60 * 60)
                            
                        }
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
