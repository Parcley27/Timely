//
//  EventDetailView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-06.
//

import SwiftUI

struct EventDetailView: View {
    @Binding var data: [Event]
    let event: Int
    
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showEditEventSheet: Bool = false
    @State private var showConfirmationDialog: Bool = false
    
    @State private var timeUntilEvent: String = ""
    
    init(data: Binding<[Event]>, event: Int, showEditEventSheet: Bool = false, showConfirmationDialog: Bool = false, timeUntilEvent: String = "") {
        self._data = data
        self.event = event
        self._showEditEventSheet = State(initialValue: showEditEventSheet)
        self._showConfirmationDialog = State(initialValue: showConfirmationDialog)
        self._timeUntilEvent = State(initialValue: timeUntilEvent)
    }
    
    private var deleteButton: some View {
        HStack {
            Text("Delete")
            Spacer()
            Image(systemName: "trash")
            
        }
        .foregroundStyle(.red)
    }
    
    func calculateTime(event: Event) -> String {
        return event.timeUntil
        
    }
    
    var body: some View {
            // Alternate navigation bar title
            //let navigationTitleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
        let navigationTitleWrapper = (data[event].name ?? "EventName")
            
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(data[event].name ?? "EventName")
                            .font(.title)
                            .bold()
                        
                        Text(timeUntilEvent)
                            .onAppear {
                                updateTimeUntilEvent()
                                
                            }
                            .font(.title3)
                            .foregroundStyle(data[event].hasPassed ? .red : .primary)
                            .bold(data[event].hasPassed)
                        
                    }
                    
                    Spacer()
                    
                    Text(data[event].emoji ?? "📅")
                        .font(.system(size: 42))
                }
            }
            
            Section {
                HStack {
                    Text(data[event].dateString ?? "Event date and time")
                        .foregroundStyle(data[event].hasPassed ? .red : .primary)
                        .bold(data[event].hasStarted)
                    
                }
            }
            
            if data[event].description != nil {
                Section {
                    Text(data[event].description ?? "")
                    
                }
            }
            
            if data[event].isCopy ?? false {
                if let sourceEvent = data.firstIndex(where: { $0.id == data[event].copyOfEventWithID }) {
                    Section {
                        NavigationLink(destination: EventDetailView(data: $data, event: sourceEvent)) {
                            Text("View Original Event")
                            
                        }
                        .bold()
                        .foregroundStyle(.selection)
                        
                    }
                }
            }
            
            if data[event].isCopy ?? false {
                let totalCopies = data.filter { $0.copyOfEventWithID == data[event].copyOfEventWithID }
                
                Section {
                    Text("Copy \(data[event].copyNumber ?? 0) of \(totalCopies.count), repeating \(NSLocalizedString(data[event].recurranceRate!, comment: ""))")
                    
                }
            }
            
            Section {
                Toggle("Favourite", isOn: $data[event].isFavourite)
                    .onChange(of: data[event].isFavourite) { newValue in
                        Task {
                            do {
                                try await EventStore().save(events: data)
                                
                            } catch {
                                fatalError(error.localizedDescription)
                                
                            }
                        }
                    }
                
                Toggle("Mute", isOn: $data[event].isMuted)
                    .onChange(of: data[event].isMuted) { newValue in
                        Task {
                            do {
                                try await EventStore().save(events: data)
                                
                            } catch {
                                fatalError(error.localizedDescription)
                                
                            }
                        }
                    }
            }
            
            Section {
                Button {
                    showConfirmationDialog = true
                    
                } label: {
                    deleteButton
                    
                }
                .confirmationDialog(Text("Delete \"\(data[event].name!)\" ?"),
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible,
                    actions: {
                        Button("Delete", role: .destructive) {
                            print("Delete Event")
                            
                            NotificationManager().removeAllNotifications()
                            
                            presentationMode.wrappedValue.dismiss()
                            dismiss()
                            
                            data.remove(at: event)
                            
                        }
                    },
                    message: {
                        Text("This action cannot be undone")
                    
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Edit event")
                    showEditEventSheet = true
                    
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                    
                }
            }
        }
        .navigationBarTitle(navigationTitleWrapper, displayMode: .inline)
        .sheet(isPresented: $showEditEventSheet) {
            EditEventSheetView(data: $data, event: event)
            
        }
    }
    
    private func updateTimeUntilEvent() {
        timeUntilEvent = calculateTime(event: data[event])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateTimeUntilEvent()
            
        }
    }
}

struct EventDetailViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        
        return EventDetailView(data: previewEvents, event: 0)
        
    }
}
