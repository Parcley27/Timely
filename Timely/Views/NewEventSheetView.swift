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
    @StateObject private var notificationManager = NotificationManager()
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
        if formEmoji.isEmpty || formEmoji == "" {
            
            formEmoji = "📅"
            
            var hasFoundEmoji = false
            
            formName = formName.trimmingCharacters(in: .whitespaces)
            
            for character in formName {
                let unicodeScalars = character.unicodeScalars
                
                for scalar in unicodeScalars {
                    switch scalar.value {
                    case 0x1F600...0x1F64F, // Emoticons
                         0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                         0x1F680...0x1F6FF, // Transport and Map
                         0x2600...0x26FF,   // Misc symbols
                         0x2700...0x27BF,   // Dingbats
                         0xFE00...0xFE0F,   // Variation Selectors
                         0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                         0x1F1E6...0x1F1FF: // Flags
                        hasFoundEmoji = true
                        
                    default:
                        continue
                        
                    }
                }
                
                if hasFoundEmoji {
                    formEmoji = String(character)
                    
                    if let characterIndex = formName.firstIndex(of: character) {
                        formName.remove(at: characterIndex)
                        
                    }
                    
                    break
                    
                }
            }
            
        } else {
            formEmoji = String(formEmoji.prefix(1))
            
        }
        
        let newEvent = Event (
            name: formName.trimmingCharacters(in: .whitespaces),
            emoji: formEmoji,
            description: (formDescription != "" ? formDescription.trimmingCharacters(in: .whitespaces) : nil),
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
                notificationManager.scheduleNotifications(for: newEvent)
                
            } catch {
                fatalError(error.localizedDescription)
                
            }
        }
        
        print("Saving event: \(newEvent)")
        
        for event in data {
            print(event.name!, terminator: ", ")
            print("")
            
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
                        
                        //TextField("Emoji", text: $formEmoji)
                        
                        EmojiTextField(text: $formEmoji, placeholder: NSLocalizedString("Emoji", comment: ""))
                        
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Start Time", selection: $formDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute, .date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                        if !preferences.quickAdd {
                            DatePicker("End Time", selection: $formEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                            
                        }
                        
                        //DatePicker("End Time", selection: $formEndDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute])
                        // DEBUG - Display date information
                        //Text("\(formatTime(inputDate: formDateAndTime))")
                        
                    }
                    .onChange(of: formDateAndTime) { _ in
                        formEndDateAndTime = formDateAndTime.addingTimeInterval(60 * 60)
                        
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
