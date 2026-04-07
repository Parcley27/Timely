//
//  EditEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-01-26.
//

import SwiftUI
import PhotosUI

struct EditEventSheetView: View {
    init(data: Binding<[Event]>, eventID: UUID) {
        self._data = data
        self.eventID = eventID
        
        UIDatePicker.appearance().minuteInterval = 1
        
    }
    
    @Binding var data: [Event]
    let eventID: UUID
    
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var preferences: SettingsStore
    
    @Environment(\.dismiss) var dismiss
    
    @State var showConfirmationDialog = false
    
    let calendar = Calendar.current
    
    let recurringTimeOptions: [String] = ["never", "daily", "weekly", "monthly", "annually"]
    
    @State private var isEditing = false
    
    @State var editedName: String = ""
    @State var editedEmoji: String = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isLoadingImage: Bool = false
    @State private var editedImageData: Data? = nil
    @State private var imageWasChanged: Bool = false
    
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
        guard let eventIndex = data.firstIndex(where: { $0.id == eventID }) else { return }
        
        if editedEmoji == "" {
            for character in editedName {
                if data[eventIndex].emoji == String(character) {
                    editedEmoji = String(character)
                    
                    if let characterIndex = editedName.firstIndex(of: Character(editedEmoji)) {
                        editedName.remove(at: characterIndex)
                        
                    }
                    
                    break
                    
                }
            }
            
            if editedEmoji == "" {
                for character in editedName {
                    if character.unicodeScalars.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation }) {
                        editedEmoji = String(character)
                        
                        if let characterIndex = editedName.firstIndex(of: Character(editedEmoji)) {
                            editedName.remove(at: characterIndex)
                            
                        }
                        
                        break
                        
                    }
                }
            }
            
            if editedEmoji == "" {
                editedEmoji = "📅"
                
            }
            
        } else {
            editedEmoji = String(editedEmoji.prefix(1))
            
        }
        
        data[eventIndex].name = editedName.trimmingCharacters(in: .whitespaces)
        data[eventIndex].emoji = editedEmoji
        
        if editedDescription != "" {
            data[eventIndex].description = editedDescription.trimmingCharacters(in: .whitespaces)
            
        } else {
            data[eventIndex].description = nil
            
        }
        
        data[eventIndex].dateAndTime = editedDateAndTime
        data[eventIndex].endDateAndTime = editedEndDateAndTime
        data[eventIndex].isAllDay = editedIsAllDay
        
        data[eventIndex].isRecurring = editedIsRecurring
        data[eventIndex].recurranceRate = editedRecurringRate
        data[eventIndex].recurringTimes = editedIsRecurring ? Int(editedRecurringTimes) : 1
        
        data[eventIndex].isFavourite = editedFavourite
        data[eventIndex].isMuted = editedMute
        
        if imageWasChanged {
            if let oldFilename = data[eventIndex].imageFilename {
                eventStore.deleteImage(filename: oldFilename)
                
            }
            
            if let uiImage = editedImageData.flatMap({ UIImage(data: $0) }) {
                data[eventIndex].imageFilename = eventStore.saveImage(uiImage, for: data[eventIndex].id)
                
            } else {
                data[eventIndex].imageFilename = nil
                
            }
        }
        
        data.sort(by: { $0.dateAndTime < $1.dateAndTime })
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [data[eventIndex].id.uuidString])
        
        Task {
            do {
                try await eventStore.save(events: data)
                
            } catch {
                eventStore.saveError = error
                
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
        
        VStack(spacing: 0) {
            if data[eventIndex].isCopy ?? false {
                Text(NSLocalizedString("Note: Changes made apply only to this event", comment: ""))
                    .foregroundStyle(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                
            }
            
            Form {
                Section(NSLocalizedString("About", comment: "")) {
                    TextField(data[eventIndex].name ?? NSLocalizedString("Name", comment: ""), text: $editedName)
                        .textInputAutocapitalization(.words)
                    
                    if preferences.useEmojiKeyboard {
                        EmojiTextField(text: $editedEmoji, placeholder: data[eventIndex].emoji ?? "📅")
                            .opacity(editedEmoji == "" ? 0.5: 1.0)

                    } else {
                        TextField(data[eventIndex].emoji ?? "📅", text: $editedEmoji)
                            .opacity(editedEmoji == "" ? 0.5: 1.0)
                        
                    }
                    
                }
                
                Section(NSLocalizedString("Date and Time", comment: "")) {
                    DatePicker(NSLocalizedString("Start Time", comment: ""), selection: $editedDateAndTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .opacity(!editedIsAllDay ? 1.0 : 0.5)
                    
                    DatePicker(NSLocalizedString("End Time", comment: ""), selection: $editedEndDateAndTime, in: timesAfterStart, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .opacity(!editedIsAllDay ? 1.0 : 0.5)
                        .disabled(editedIsAllDay)
                    
                    Toggle(NSLocalizedString("All Day", comment: ""), isOn: $editedIsAllDay)
                        .onChange(of: editedIsAllDay) { _, newValue in
                            if newValue {
                                editedDateAndTime = setTime(for: editedDateAndTime, hour: 0, minute: 0, second: 0) ?? editedDateAndTime
                                editedEndDateAndTime = setTime(for: editedDateAndTime, hour: 23, minute: 59, second: 59) ?? editedEndDateAndTime
                                
                            }
                        }
                        .padding(.vertical, 8)
                    
                }
                .onChange(of: editedDateAndTime) { _, _ in
                    if !editedIsAllDay {
                        let eventLength = editedEndDateAndTime.timeIntervalSince(dummyDateAndTime)
                        
                        editedEndDateAndTime = editedDateAndTime.addingTimeInterval(eventLength)
                        dummyDateAndTime = editedDateAndTime
                        
                    }
                }
                
                Section(NSLocalizedString("Repeating", comment: "")) {
                    Picker(editedRecurringRate != "never" ? NSLocalizedString("Occurs", comment: "") : NSLocalizedString("Never", comment: ""), selection: $editedRecurringRate) {
                        ForEach(recurringTimeOptions, id: \.self) { timeOption in
                            Text(NSLocalizedString(timeOption.capitalized, comment: ""))
                                .id(timeOption)
                        }
                    }
                    .onChange(of: editedRecurringRate) {
                        if editedRecurringRate == "never" {
                            editedIsRecurring = false
                            editedRecurringTimes = 2 // Reset to sensible default
                            
                        } else {
                            editedIsRecurring = true
                            if editedRecurringTimes < 2 {
                                editedRecurringTimes = 2 // Minimum 2 occurrences
                                
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Only show stepper when actively recurring
                    if editedRecurringRate != "never" {
                        let timesCount = Int(editedRecurringTimes) - 1
                        let timesText = timesCount == 1 ? NSLocalizedString("time", comment: "") : NSLocalizedString("times", comment: "")
                        Stepper(String.localizedStringWithFormat(NSLocalizedString("Repeats %d %@", comment: ""), timesCount, timesText), value: $editedRecurringTimes, in: 2...100, step: 1)
                        
                    }
                    
                }
                .disabled(data[eventIndex].isCopy ?? false)
                
                Section(NSLocalizedString("Details", comment: "")) {
                    ZStack {
                        HStack {
                            Text(NSLocalizedString("Description", comment: ""))
                                .foregroundStyle(.quaternary)
                                .opacity(editedDescription == "" ? 100 : 0)
                                .padding(.leading, 4)
                            
                            Spacer()
                            
                        }
                        
                        TextEditor(text: $editedDescription)
                        
                    }
                }
                
                Section(NSLocalizedString("Importance", comment: "")) {
                    Toggle(NSLocalizedString("Favourite", comment: ""), isOn: $editedFavourite)
                    
                    Toggle(NSLocalizedString("Muted", comment: ""), isOn: $editedMute)
                    
                }
                
                Section("Customization") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Text(editedImageData != nil ? "Change Photo" : "Choose Photo")
                            
                            Spacer()
                            
                            Image(systemName: "photo")
                            
                        }
                    }
                    
                    if let editedImageData, let uiImage = UIImage(data: editedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowInsets(EdgeInsets())
                            .padding()
                    }
                    
                    if editedImageData != nil {
                        Button(role: .destructive) {
                            editedImageData = nil
                            selectedPhotoItem = nil
                            imageWasChanged = true
                            
                        } label : {
                            HStack {
                                Text("Remove Photo")
                                
                                Spacer()
                                
                                Image(systemName: "trash")
                                
                            }
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) {
                    guard let selectedPhotoItem else { return }
                    
                    isLoadingImage = true
                    
                    Task {
                        if let imageData = try? await selectedPhotoItem.loadTransferable(type: Data.self) {
                            editedImageData = imageData
                            imageWasChanged = true
                            
                        }
                        
                        await MainActor.run {
                            isLoadingImage = false
                            
                        }
                    }
                }
            }
            .onAppear {
                // Initialize ALL values once when the form appears
                editedName = data[eventIndex].name ?? "Name"
                editedEmoji = data[eventIndex].emoji ?? "📅"
                
                if let filename = data[eventIndex].imageFilename {
                    editedImageData = eventStore.loadImage(filename: filename)
                        .flatMap { $0.jpegData(compressionQuality: 1.0) }

                }
                
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
            .scrollDismissesKeyboard(.interactively)
            
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("Save", comment: "")) {
                    if (data.filter{ $0.copyOfEventWithID == eventID }).count > 0 || editedIsRecurring {
                        showConfirmationDialog = true
                        
                    } else {
                        saveEvent()
                        dismiss()
                        
                    }
                }
                .confirmationDialog(Text(NSLocalizedString("This Event has Recurring Copies", comment: "")),
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible,
                    actions: {
                        Button(NSLocalizedString("Edit All Copies", comment: "")) {
                            saveEvent()
                            
                            for event in (data.filter{ $0.copyOfEventWithID == eventID }) {
                                if let eventIndex = data.firstIndex(where: {$0.id == event.id}) {
                                    data.remove(at: eventIndex)
                                    
                                }
                            }
                            
                            // Only iterate if there are copies to create
                            if editedIsRecurring && editedRecurringTimes >= 2 {
                                for recurringSpace in 1 ... (Int(editedRecurringTimes) - 1) {
                                    let newRecurringEvent = Event (
                                        name: editedName.trimmingCharacters(in: .whitespaces),
                                        emoji: editedEmoji,
                                        
                                        description: (editedDescription != "" ? editedDescription.trimmingCharacters(in: .whitespaces) : nil),
                                        
                                        dateAndTime: moveDate(editedDateAndTime, by: editedRecurringRate, amount: recurringSpace),
                                        endDateAndTime: moveDate(editedEndDateAndTime, by: editedRecurringRate, amount: recurringSpace),
                                        isAllDay: editedIsAllDay,
                                        
                                        recurranceRate: editedRecurringRate,
                                        
                                        isCopy: true,
                                        copyOfEventWithID: eventID,
                                        copyNumber: recurringSpace,
                                        
                                        isFavourite: editedFavourite,
                                        isMuted: editedMute
                                    )
                                    
                                    data.append(newRecurringEvent)
                                    
                                }
                            }
                            
                            Task {
                                do {
                                    try await eventStore.save(events: data)
                                } catch {
                                    eventStore.saveError = error
                                }
                            }
                            
                            dismiss()
                        }
                    },
                    message: {
                        Text(NSLocalizedString("This action will edit all copies of your Event", comment: ""))
                    
                    }
                )
                .disabled(editedName == "")
                
            }
        }
        .navigationBarTitle(NSLocalizedString("Edit Event", comment: ""), displayMode: .inline)
        .onChange(of: eventID) {
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
        .onAppear {
            if !data.contains(where: { $0.id == eventID }) {
                dismiss()
                
            }
        }
        .onChange(of: data) {
            if !data.contains(where: { $0.id == eventID }) {
                dismiss()
                
            }
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
        
        return EditEventSheetView(data: previewEvents, eventID: previewEvents[0].id)
            .environmentObject(EventStore())
            .environmentObject(SettingsStore())
        
    }
}
