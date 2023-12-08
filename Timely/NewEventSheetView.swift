//
//  NewEventSheetView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-18.
//

import SwiftUI
import Foundation

struct NewEventSheetView: View {
    @EnvironmentObject var data: EventData

    @Environment(\.dismiss) var dismiss
        
    @State private var formName: String = ""
    @State private var formEmoji: String = ""
    @State private var formDescription: String = ""
    @State private var formDateAndTime: Date = {
        let currentDate = Date()
        let oneDayInSeconds: TimeInterval = 24 * 60 * 60
        return currentDate.addingTimeInterval(oneDayInSeconds)
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
        }
        
        let newEvent = Event (
            name: formName,
            emoji: formEmoji,
            description: formDescription,
            dateAndTime: formDateAndTime,
            isFavourite: formFavourited,
            isMuted: formMuted
        )
        
        data.events.append(newEvent)

    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section("About") {
                        TextField("Event Name", text: $formName)
                        TextField("Event Emoji (Optional)", text: $formEmoji)
                    }
                    
                    Section() {
                        TextField("Description", text: $formDescription)
                    }
                    
                    Section("Date and Time") {
                        DatePicker("Date", selection: $formDateAndTime, displayedComponents: [.date])
                        DatePicker("Time", selection: $formDateAndTime, displayedComponents: [.hourAndMinute])
                        // DEBUG - Display date information
                        //Text("\(formatTime(inputDate: formDateAndTime))")
                    }
                    
                    Section("More") {
                        Toggle("Favourite", isOn: $formFavourited)
                        Toggle("Mute", isOn: $formMuted)
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
                    Button ("Done") {
                        // Chanage to add new data to EventData
                        createEvent()
                        
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
        NewEventSheetView()
    }
}
