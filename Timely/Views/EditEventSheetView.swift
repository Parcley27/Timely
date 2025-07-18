//
//  EditEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-01-26.
//

import SwiftUI

struct EditEventSheetView: View {
    init(data: Binding<[Event]>, eventID: UUID) {
        self._data = data
        self.eventID = eventID
        
        UIDatePicker.appearance().minuteInterval = 1
        
    }
    
    @Binding var data: [Event]
    let eventID: UUID
    
    @Environment(\.dismiss) var dismiss
    
    @State var showConfirmationDialog = false
    
    let calendar = Calendar.current
    
    let recurringTimeOptions: [String] = ["never", "daily", "weekly", "monthly", "annually"]
    
    @State private var isEditing = false
    
    @State var editedName: String = ""
    @State var editedEmoji: String = ""
    
    @State var editedDescription: String = ""
    
    @State var editedDateAndTime: Date = Date()
    @State var editedEndDateAndTime: Date = Date()
    
    @State var dummyDateAndTime: Date = Date()
    
    @State var editedIsAllDay: Bool = false
    
    @State var editedIsRecurring: Bool = false
    @State var editedRecurringRate: String = "never"
    @State var editedRecurringTimes: Double = 2.0
    
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
    
    func setTime(for date: Date, hour: Int, minute: Int, second: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return calendar.date(from: components)
        
    }
    
    func saveEvent() {
        let eventIndex = data.firstIndex(where: { $0.id == eventID })!
        
        data[eventIndex].name = editedName.trimmingCharacters(in: .whitespaces)
        
        if editedEmoji == "" {
            var hasFoundEmoji = false
            
            for character in editedName {
                let unicodeScalars = character.unicodeScalars
                
                for scalar in unicodeScalars {
                    if (scalar.value >= 0x1F600 && scalar.value <= 0x1F64F) {
                        data[eventIndex].emoji = String(character)
                        hasFoundEmoji = true
                        
                        if let characterIndex = editedName.firstIndex(of: character) {
                            editedName.remove(at: characterIndex)
                            
                        }
                        
                        break
                        
                    }
                }
                
                if hasFoundEmoji {
                    break
                    
                }
            }
            
        } else {
            editedEmoji = String(editedEmoji.prefix(1))
            data[eventIndex].emoji = editedEmoji
            
        }
        
        if editedDescription != "" {
            data[eventIndex].description = editedDescription.trimmingCharacters(in: .whitespaces)
            
        }
        
        data[eventIndex].dateAndTime = editedDateAndTime
        data[eventIndex].endDateAndTime = editedEndDateAndTime
        data[eventIndex].isAllDay = editedIsAllDay
        
        data[eventIndex].isRecurring = editedIsRecurring
        data[eventIndex].recurranceRate = editedRecurringRate
        data[eventIndex].recurringTimes = editedIsRecurring ? Int(editedRecurringTimes) : 1
        
        data[eventIndex].isFavourite = editedFavourite
        data[eventIndex].isMuted = editedMute
        
        data.sort(by: { $0.dateAndTime < $1.dateAndTime })
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [data[eventIndex].id.uuidString])
        
        Task {
            do {
                try await EventStore().save(events: data)
                
            } catch {
                fatalError(error.localizedDescription)
                
            }
        }
        
        print(data[eventIndex])
        
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
    
    var body: some View {
        let eventIndex = data.firstIndex(where: { $0.id == eventID })!
        
        NavigationStack {
            
            VStack(spacing: 0) {
                if data[eventIndex].isCopy ?? false {
                    Text("Note: Changes made apply only to this event")
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                    
                }
                
                Form {
                    Section("About") {
                        TextField(data[eventIndex].name ?? "Name", text: $editedName)
                            .textInputAutocapitalization(.words)
                            .onAppear() {
                                editedName = data[eventIndex].name ?? "Name"
                                
                            }
                        
                        EmojiTextField(text: $editedEmoji, placeholder: data[eventIndex].emoji ?? "📅")
                            .onAppear() {
                                editedEmoji = data[eventIndex].emoji ?? "📅"
                                
                            }
                            .opacity(editedEmoji == "" ? 0.5: 1.0)
                        
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Start Date", selection: $editedDateAndTime, displayedComponents: [.date])
                            .datePickerStyle(GraphicalDatePickerStyle())
                        
                        HStack {
                            Text("Start Time")
                            
                            DatePicker(" ", selection: $editedDateAndTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                            
                        }
                        .disabled(editedIsAllDay)
                        .opacity(!editedIsAllDay ? 1.0 : 0.5)
                        
                        Toggle("All Day", isOn: $editedIsAllDay)
                            .onChange(of: editedIsAllDay) { _ in
                                if editedIsAllDay {
                                    editedDateAndTime = setTime(for: editedDateAndTime, hour: 0, minute: 0, second: 0) ?? editedDateAndTime
                                    editedEndDateAndTime = setTime(for: editedDateAndTime, hour: 23, minute: 59, second: 59) ?? editedEndDateAndTime
                                    
                                }
                            }
                            .padding(.vertical, 8)                        
                        
                        DatePicker("End Time", selection: $editedEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding(.vertical, 8)
                            .opacity(!editedIsAllDay ? 1.0 : 0.5)
                            .disabled(editedIsAllDay)
                        
                    }
                    .onAppear() {
                        //print("BEFORE")
                        //print(Date())
                        //print(data[event].dateAndTime)
                        editedDateAndTime = data[eventIndex].dateAndTime
                        editedEndDateAndTime = data[eventIndex].endDateAndTime ?? data[eventIndex].dateAndTime
                        dummyDateAndTime = data[eventIndex].dateAndTime
                        
                        editedIsAllDay = data[eventIndex].isAllDay ?? false
                        //print("AFTER")
                        //print(editedDateAndTime)
                        
                    }
                    .onChange(of: editedDateAndTime) { _ in
                        if !editedIsAllDay {
                            let eventLength = editedEndDateAndTime.timeIntervalSince(dummyDateAndTime)
                            
                            editedEndDateAndTime = editedDateAndTime.addingTimeInterval(eventLength)
                            dummyDateAndTime = editedDateAndTime
                            
                        }
                    }
                    
                    Section("Repeating") {
                        Picker(editedRecurringRate != "never" ? (editedRecurringTimes < 10.5 ? String(format: "Repeating %.0f times", editedRecurringTimes) : "Repeating forever") : "Repeating" , selection: $editedRecurringRate) {
                            ForEach(recurringTimeOptions, id: \.self) { timeOption in
                                Text(timeOption.capitalized)
                                    .id(timeOption)
                                
                            }
                        }
                        .onChange(of: editedRecurringRate) { _ in
                            if editedRecurringRate == "never" {
                                editedIsRecurring = false
                                
                            } else {
                                editedIsRecurring = true
                                
                            }
                        }
                        .pickerStyle(.menu )
                        
                        if editedIsRecurring {
                            Slider(
                                value: $editedRecurringTimes,
                                        in: 1 ... 10,
                                        onEditingChanged: { editing in
                                            if !editing {
                                                editedRecurringTimes = editedRecurringTimes.rounded()
                                                
                                                if editedRecurringTimes == 1 {
                                                    editedIsRecurring = false
                                                    editedRecurringRate = "never"
                                                    
                                                    editedRecurringTimes = 2
                                                    
                                                }
                                                
                                            }
                                        }
                                    )
                            
                        }
                    }
                    .onChange(of: editedRecurringRate) { _ in
                        if editedRecurringRate == "never" {
                            editedIsRecurring = false
                            
                        } else {
                            editedIsRecurring = true
                            
                        }
                    }
                    .disabled(data[eventIndex].isCopy ?? false)
                    .onAppear() {
                        editedIsRecurring = data[eventIndex].isRecurring ?? false
                        editedRecurringRate = data[eventIndex].recurranceRate ?? "never"
                        editedRecurringTimes = Double(data[eventIndex].recurringTimes ?? 0)
                        
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
                        editedDescription = data[eventIndex].description ?? ""
                        
                    }
                    
                    Section("Importance") {
                        Toggle("Favourite", isOn: $editedFavourite)
                            .onAppear() {
                                editedFavourite = data[eventIndex].isFavourite
                                
                            }
                        
                        Toggle("Muted", isOn: $editedMute)
                            .onAppear() {
                                editedMute = data[eventIndex].isMuted
                                
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
                        if (data.filter{ $0.copyOfEventWithID == eventID }).count > 0 || editedIsRecurring {
                            showConfirmationDialog = true
                            
                        } else {
                            saveEvent()
                            dismiss()
                            
                        }//data.firstIndex(where: {$0.id == eventID})
                    }
                    .confirmationDialog(Text("This event has recurring copies!"),
                        isPresented: $showConfirmationDialog,
                        titleVisibility: .visible,
                        actions: {
                            Button("Edit All Copies") {
                                saveEvent()
                                
                                for event in (data.filter{ $0.copyOfEventWithID == eventID }) {
                                    if let eventIndex = data.firstIndex(where: {$0.id == event.id}) {
                                        data.remove(at: eventIndex)
                                        
                                    }
                                    
                                    Task {
                                        do {
                                            try await EventStore().save(events: data)
                                            
                                        } catch {
                                            fatalError(error.localizedDescription)
                                            
                                        }
                                    }
                                }
                                
                                if editedIsRecurring {
                                    for recurringSpace in 1 ... (Int(editedRecurringTimes) - 1) {
                                        let newRecurringEvent = Event (
                                            name: editedName.trimmingCharacters(in: .whitespaces),
                                            emoji: editedEmoji,
                                            
                                            description: (editedDescription != "" ? editedDescription.trimmingCharacters(in: .whitespaces) : nil),
                                            
                                            dateAndTime: moveDate(editedDateAndTime, by: editedRecurringRate, amount: recurringSpace),
                                            endDateAndTime: moveDate(editedEndDateAndTime, by: editedRecurringRate, amount: recurringSpace),
                                            isAllDay: editedIsAllDay,
                                            
                                            //isRecurring: formIsRecurring,
                                            recurranceRate: editedRecurringRate,
                                            //recurringTimes: Int(formRecurringTimes),
                                            
                                            isCopy: true,
                                            copyOfEventWithID: eventID,
                                            copyNumber: recurringSpace,
                                            
                                            isFavourite: editedFavourite,
                                            isMuted: editedMute
                                            
                                        )
                                        
                                        data.append(newRecurringEvent)
                                        
                                        Task {
                                            do {
                                                try await EventStore().save(events: data)
                                                
                                            } catch {
                                                fatalError(error.localizedDescription)
                                                
                                            }
                                        }
                                    }
                                }
                                
                                dismiss()
                                
                            }
                        },
                        message: {
                            Text("This action will edit all copies of this event")
                        
                        }
                    )
                    .disabled(editedName == "")
                    
                }
            }
            .navigationBarTitle("Edit Event", displayMode: .inline)
            .onChange(of: eventID) { _ in
                // Reset all state variables when editing a different event
                let eventIndex = data.firstIndex(where: { $0.id == eventID })!
                
                editedName = data[eventIndex].name ?? "Name"
                editedEmoji = data[eventIndex].emoji ?? "📅"
                editedDescription = data[eventIndex].description ?? ""
                
                editedDateAndTime = data[eventIndex].dateAndTime
                editedEndDateAndTime = data[eventIndex].endDateAndTime ?? data[eventIndex].dateAndTime
                dummyDateAndTime = data[eventIndex].dateAndTime
                
                editedIsAllDay = data[eventIndex].isAllDay ?? false
                
                editedIsRecurring = data[eventIndex].isRecurring ?? false
                editedRecurringRate = data[eventIndex].recurranceRate ?? "never"
                editedRecurringTimes = Double(data[eventIndex].recurringTimes ?? 0)
                
                editedFavourite = data[eventIndex].isFavourite
                editedMute = data[eventIndex].isMuted
                
            }
            
        }
//        .onAppear {
//            eventIndex = data.firstIndex(where: { $0.id == eventID })!
//            
//        }
    }
}

struct EditEventSheetViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        
        return EditEventSheetView(data: previewEvents, eventID: previewEvents[0].id)
        
    }
}
