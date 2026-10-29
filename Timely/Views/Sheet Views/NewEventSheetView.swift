//
//  NewEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-18.
//

import SwiftUI
import Foundation
import PhotosUI

struct NewEventSheetView: View {
    init(data: Binding<[Event]>) {
        self._data = data
        
        if SettingsStore().quickAdd {
            UIDatePicker.appearance().minuteInterval = 15
            
        } else {
            UIDatePicker.appearance().minuteInterval = 5
            
        }
        
        let start = Self.defaultStart(from: Date(), minuteInterval: SettingsStore().quickAdd ? 15 : 5)
        self._formDateAndTime = State(initialValue: start)
        self._formEndDateAndTime = State(initialValue: start.addingTimeInterval(60 * 60))
        self._dummyDateAndTime = State(initialValue: start)
        
    }
    
    @Binding var data: [Event]
    
    @EnvironmentObject private var eventStore: EventStore
    
    @StateObject private var preferences = SettingsStore()
    
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var isEditing = false
    
    let calendar = Calendar.current
    
    let recurringTimeOptions: [String] = ["never", "daily", "weekly", "monthly", "annually"]
    
    @State private var formName: String = ""
    @State private var formEmoji: String = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isLoadingImage: Bool = false
    @State private var imageData: Data? = nil
    
    @State private var formDescription: String = ""
    
    // Start, end and dummy are all derived from one base date in init so the default event length is exactly one hour
    @State private var formDateAndTime: Date
    @State private var formEndDateAndTime: Date
    @State private var dummyDateAndTime: Date
    
    // The date pickers snap to this many minutes, so the defaults must already sit on that grid.
    // Otherwise each picker snaps on its own (e.g. :07 -> :05 but :08 -> :10) and the gap between start and end drifts
    private static func defaultStart(from now: Date, minuteInterval: Int) -> Date {
        let calendar = Calendar.current
        
        // Aim for one hour out, drop the seconds, then move forward to the next picker slot
        let target = now.addingTimeInterval(60 * 60)
        let wholeMinute = calendar.dateInterval(of: .minute, for: target)?.start ?? target
        let minute = calendar.component(.minute, from: wholeMinute)
        let minutesToSlot = (minuteInterval - minute % minuteInterval) % minuteInterval
        
        return wholeMinute.addingTimeInterval(TimeInterval(minutesToSlot * 60))
        
    }
    
    @State private var formTiming: EventTiming = .timed
    
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
    
    func createEvent() {
        if formEmoji == "" {
            var hasFoundEmoji = false
            
            for character in formName {
                if character.unicodeScalars.allSatisfy({ $0.properties.isEmoji && $0.properties.isEmojiPresentation }) {
                    formEmoji = String(character)
                    hasFoundEmoji = true
                    
                    if let characterIndex = formName.firstIndex(of: character) {
                        formName.remove(at: characterIndex)
                        
                    }
                    
                    break
                    
                }
            }
            
            if !hasFoundEmoji {
                formEmoji = "📅"
                
            }
            
        } else {
            formEmoji = String(formEmoji.prefix(1))
            
        }
        
        var newEvent = Event (
            name: formName.trimmingCharacters(in: .whitespaces),
            emoji: formEmoji,
            
            description: (formDescription != "" ? formDescription.trimmingCharacters(in: .whitespaces) : nil),
            
            dateAndTime: formDateAndTime,
            endDateAndTime: formTiming == .moment ? nil : formEndDateAndTime,
            timing: formTiming,
            
            isRecurring: formIsRecurring,
            recurranceRate: formRecurringRate,
            recurringTimes: formIsRecurring ? Int(formRecurringTimes) : 1,
            
            isFavourite: formFavourited,
            isMuted: formMuted
            
        )
        
        // Save image if one was selected
        if let uiImage = imageData.flatMap({ UIImage(data: $0) }) {
            newEvent.imageFilename = eventStore.saveImage(uiImage, for: newEvent.id)
            
        }
                
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
                        endDateAndTime: formTiming == .moment ? nil : moveDate(formEndDateAndTime, by: formRecurringRate, amount: recurringSpace),
                        timing: formTiming,
                        
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
                try await eventStore.save(events: data)
                
            } catch {
                eventStore.saveError = error
                
            }
        }
        
        print("Saving event: \(newEvent)")
        
        for event in data {
            print(event.name ?? "Event Name", terminator: ", ")
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
                    
                    EventDateTimeSection(start: $formDateAndTime, previousStart: $dummyDateAndTime, end: $formEndDateAndTime, timing: $formTiming, startRange: dateRange)
                    
                    if !preferences.quickAdd {
                        Section("Repeating") {
                            Picker(formRecurringRate != "never" ? NSLocalizedString("Occurs", comment: "") : NSLocalizedString("Never", comment: ""), selection: $formRecurringRate) {
                                ForEach(recurringTimeOptions, id: \.self) { timeOption in
                                    Text(timeOption.capitalized)
                                        .id(timeOption)
                                    
                                }
                            }
                            .onChange(of: formRecurringRate) { _, newValue in
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
                    
                    if !preferences.quickAdd {
                        Section("Customization") {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    Text(imageData != nil ? "Change Photo" : "Choose Photo")
                                    
                                    Spacer()
                                    
                                    Image(systemName: "photo")
                                    
                                }
                            }
                            
                            if let imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .listRowInsets(EdgeInsets())
                                    .padding()
                                
                            }
                            
                            if imageData != nil {
                                Button(role: .destructive) {
                                    imageData = nil
                                    selectedPhotoItem = nil
                                    
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
                                if let newImageData = try? await selectedPhotoItem.loadTransferable(type: Data.self) {
                                    imageData = newImageData
                                    
                                }
                                
                                await MainActor.run {
                                    isLoadingImage = false
                                    
                                }
                            }
                        }
                    }
                    
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(preferences.showFilmGrain ? .hidden : .visible)
            .background {
                if preferences.showFilmGrain {
                    NoiseView()
                    
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
