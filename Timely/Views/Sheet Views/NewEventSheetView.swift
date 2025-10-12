//
//  NewEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-18.
//

import SwiftUI
import Foundation

struct NewEventSheetView: View {
    
    init(data: Binding<[Event]>) {
        self._data = data
        
        if SettingsStore().quickAdd {
            UIDatePicker.appearance().minuteInterval = 15
            
        } else {
            UIDatePicker.appearance().minuteInterval = 5
            
        }
    }
    
    @Binding var data: [Event]
    @StateObject private var store = EventStore()
    @StateObject private var preferences = SettingsStore()
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var isEditing = false
    
    let calendar = Calendar.current
    
    let recurringTimeOptions: [String] = ["never", "daily", "weekly", "monthly", "annually"]
    
    @State private var formName: String = ""
    @State private var formEmoji: String = ""
    
    @State private var formDescription: String = ""
    
    @State private var formDateAndTime: Date = {
        let currentDate = Date()
        let calendar = Calendar.current
        let oneHourInSeconds: TimeInterval = 60 * 60
        
        // Round to nearest 5 minutes if quick add is enabled
        if SettingsStore().quickAdd {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            let minute = components.minute ?? 0
            let roundedMinute = Int(ceil(Double(minute) / 5.0) * 5.0)
            
            var newComponents = components
            newComponents.minute = roundedMinute % 60
            
            if roundedMinute >= 60 {
                newComponents.hour = (components.hour ?? 0) + 1
            }
            
            if let roundedDate = calendar.date(from: newComponents) {
                return roundedDate.addingTimeInterval(oneHourInSeconds)
                
            }
        }
        
        return currentDate.addingTimeInterval(oneHourInSeconds)
        
    }()

    @State private var formEndDateAndTime: Date = {
        let currentDate = Date()
        let calendar = Calendar.current
        let twoHoursInSeconds: TimeInterval = 2 * 60 * 60
        
        // Round to nearest 5 minutes if quick add is enabled
        if SettingsStore().quickAdd {
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
            let minute = components.minute ?? 0
            let roundedMinute = Int(ceil(Double(minute) / 5.0) * 5.0)
            
            var newComponents = components
            newComponents.minute = roundedMinute % 60
            
            if roundedMinute >= 60 {
                newComponents.hour = (components.hour ?? 0) + 1
                
            }
            
            if let roundedDate = calendar.date(from: newComponents) {
                return roundedDate.addingTimeInterval(twoHoursInSeconds)
                
            }
        }
        
        return currentDate.addingTimeInterval(twoHoursInSeconds)
        
    }()
    
    @State private var dummyDateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        let oneHourInSeconds: TimeInterval = 60 * 60
        
        //return currentDate.addingTimeInterval(oneDayInSeconds)
        return currentDate.addingTimeInterval(oneHourInSeconds)

    }()
    
    @State private var formIsAllDay: Bool = false
    
    @State private var formIsRecurring: Bool = false
    @State private var formRecurringRate: String = "never"
    @State private var formRecurringTimes: Double = 2.0
    
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
    
    func moveDate(_ inputDate: Date, by recurrence: String, amount: Int = 1) -> Date {
        var dateComponent = DateComponents()
        
        let calendar = Calendar.current
        
        switch recurrence {
            
        case "daily":
            dateComponent.day = amount
            
        case "weekly":
            dateComponent.day = amount * 7
            
        case "monthly":
            dateComponent.month = amount
            
        case "annually":
            dateComponent.year = amount
            
        default:
            return inputDate
            
        }
        
        if let newDate = calendar.date(byAdding: dateComponent, to: inputDate) {
            return newDate
        }
        
        return inputDate
            
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
    
    func setTime(for date: Date, hour: Int, minute: Int, second: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return calendar.date(from: components)
        
    }
    
    func createEvent() {
        if formEmoji == "" {
            var hasFoundEmoji = false
            
            for character in formName {
                let unicodeScalars = character.unicodeScalars
                
                for scalar in unicodeScalars {
                    if (scalar.value >= 0x1F600 && scalar.value <= 0x1F64F) {
                        formEmoji = String(character)
                        hasFoundEmoji = true
                        
                        if let characterIndex = formName.firstIndex(of: character) {
                            formName.remove(at: characterIndex)
                            
                        }
                        
                        break
                        
                    }
                }
                
                if hasFoundEmoji {
                    break
                    
                }
            }
            
            if !hasFoundEmoji {
                formEmoji = "📅"
                
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
            isAllDay: formIsAllDay,
            
            isRecurring: formIsRecurring,
            recurranceRate: formRecurringRate,
            recurringTimes: formIsRecurring ? Int(formRecurringTimes) : 1,
            
            isFavourite: formFavourited,
            isMuted: formMuted
            
        )
                
        data.append(newEvent)
        data.sort(by: { $0.dateAndTime < $1.dateAndTime })
        
        if formIsRecurring {
            
            // Only iterate if there are copies to create
            if formRecurringTimes >= 2 {
                for recurringSpace in 1 ... (Int(formRecurringTimes) - 1) {
                    
                    let newRecurringEvent = Event (
                        name: formName.trimmingCharacters(in: .whitespaces),
                        emoji: formEmoji,
                        
                        description: (formDescription != "" ? formDescription.trimmingCharacters(in: .whitespaces) : nil),
                        
                        dateAndTime: moveDate(formDateAndTime, by: formRecurringRate, amount: recurringSpace),
                        endDateAndTime: moveDate(formEndDateAndTime, by: formRecurringRate, amount: recurringSpace),
                        isAllDay: formIsAllDay,
                        
                        recurranceRate: formRecurringRate,
                        
                        isCopy: true,
                        copyOfEventWithID: newEvent.id,
                        copyNumber: recurringSpace,
                        
                        isFavourite: formFavourited,
                        isMuted: formMuted
                        
                    )
                    
                    data.append(newRecurringEvent)
                    
                }
            }
        }
        
        Task {
            do {
                try await store.save(events: data)
                
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
                        
                        if preferences.useEmojiKeyboard {
                            EmojiTextField(text: $formEmoji, placeholder: NSLocalizedString("Emoji", comment: ""))

                        } else {
                            TextField(NSLocalizedString("Emoji", comment: ""), text: $formEmoji)
                            
                        }
                        
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Start Date", selection: $formDateAndTime, in: dateRange, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                        HStack {
                            Text("Start Time")
                            
                            DatePicker(" ", selection: $formDateAndTime, in: dateRange, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                            
                        }
                        .disabled(formIsAllDay)
                        .opacity(!formIsAllDay ? 1.0 : 0.5)
                        
                        
                        Toggle("All Day", isOn: $formIsAllDay)
                            .onChange(of: formIsAllDay) { _ in
                                if formIsAllDay {
                                    formDateAndTime = setTime(for: formDateAndTime, hour: 0, minute: 0, second: 0) ?? formDateAndTime
                                    formEndDateAndTime = setTime(for: formDateAndTime, hour: 23, minute: 59, second: 59) ?? formEndDateAndTime
                                    
                                }
                            }
                            .padding(.vertical, 8)
                        
                        DatePicker("End Time", selection: $formEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding(.vertical, 8)
                            .opacity(!formIsAllDay ? 1.0 : 0.5)
                            .disabled(formIsAllDay)
                        
                    }
                    .onChange(of: formDateAndTime) { _ in
                        if !formIsAllDay {
                            let eventLength = formEndDateAndTime.timeIntervalSince(dummyDateAndTime)
                            
                            formEndDateAndTime = formDateAndTime.addingTimeInterval(eventLength)
                            dummyDateAndTime = formDateAndTime
                            
                        }
                    }
                    
                    if !preferences.quickAdd {
                        Section("Repeating") {
                            Picker(formRecurringRate != "never" ? NSLocalizedString("Occurs", comment: "") : NSLocalizedString("Never", comment: ""), selection: $formRecurringRate) {
                                ForEach(recurringTimeOptions, id: \.self) { timeOption in
                                    Text(timeOption.capitalized)
                                        .id(timeOption)
                                    
                                }
                            }
                            .onChange(of: formRecurringRate) { newValue in
                                if newValue == "never" {
                                    formIsRecurring = false
                                    formRecurringTimes = 2 // Reset to sensible default
                                    
                                } else {
                                    formIsRecurring = true
                                    if formRecurringTimes < 2 {
                                        formRecurringTimes = 2 // Minimum 2 occurrences
                                        
                                    }
                                }
                            }
                            .pickerStyle(.menu)
                            
                            // Only show stepper when actively recurring
                            if formRecurringRate != "never" {
                                let timesCount = Int(formRecurringTimes) - 1
                                let timesText = timesCount == 1 ? NSLocalizedString("time", comment: "") : NSLocalizedString("times", comment: "")
                                Stepper(String.localizedStringWithFormat(NSLocalizedString("Repeats %d %@", comment: ""), timesCount, timesText), value: $formRecurringTimes, in: 2...100, step: 1)
                                
                            }
                            
                        }
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
                    
                    Section("Importance") {
                        Toggle("Favourite", isOn: $formFavourited)
                        Toggle("Muted", isOn: $formMuted)
                        
                    }
                    
                    if preferences.quickAdd {
                        Section {
                            Label("Quick Add enabled: Some fields auto-filled with defaults", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
