//
//  EventDetailView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-06.
//

/*
 $data.firstIndex(where: { $0.id == event.id }) {
     data[index].isFavourite.toggle()
 */

import SwiftUI

struct EventDetailView: View {
    @Binding var data: [Event]
    let eventID: UUID
    
    @State var dataIndex: Int = 0
        
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showEditEventSheet: Bool = false
    @State private var showConfirmationDialog: Bool = false
    
    @State private var timeUntilEvent: String = ""
    
    init(data: Binding<[Event]>, eventID: UUID, showEditEventSheet: Bool = false, showConfirmationDialog: Bool = false, timeUntilEvent: String = "") {
        self._data = data
        self.eventID = eventID
        self._showEditEventSheet = State(initialValue: showEditEventSheet)
        self._showConfirmationDialog = State(initialValue: showConfirmationDialog)
        self._timeUntilEvent = State(initialValue: timeUntilEvent)
        
    }
    
    private var currentEvent: Event? {
        return data.first(where: { $0.id == eventID })
        
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
        
        
        if let event = currentEvent {
            let navigationTitleWrapper = event.name ?? "Event Name"
            
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(event.name ?? "Event Name")
                                .font(.title)
                                .bold()
                            
                            Text(timeUntilEvent)
                                .onAppear {
                                    updateTimeUntilEvent()
                                    
                                }
                                .font(.title3)
                                .foregroundStyle(event.hasPassed ? .red : .primary)
                                .bold(event.hasPassed)
                            
                        }
                        
                        Spacer()
                        
                        Text(event.emoji ?? "📅")
                            .font(.system(size: 42))
                        
                    }
                }
                .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.13) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                
                Section {
                    HStack {
                        Text(event.dateString ?? "Event date and time")
                            .foregroundStyle(event.hasPassed ? .red : .primary)
                            .bold(event.hasStarted)
                        
                    }
                }
                .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.11) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                
                
                if event.description != nil {
                    Section {
                        Text(event.description ?? "")
                        
                    }
                    .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                    
                }
                
                if event.isCopy ?? false {
                    if let sourceEvent = data.firstIndex(where: { $0.id == event.copyOfEventWithID }) {
                        Section {
                            NavigationLink(destination: EventDetailView(data: $data, eventID: data[sourceEvent].id)) {
                                Text("View Original Event")
                                
                            }
                            .bold()
                            .foregroundStyle(.selection)
                            
                        }
                        .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                        
                    }
                    
                    let totalCopies = data.filter { $0.copyOfEventWithID == event.copyOfEventWithID }
                    
                    Section {
                        Text("Copy \(event.copyNumber ?? 0) of \(totalCopies.count), repeating \(NSLocalizedString(event.recurranceRate ?? "never", comment: ""))")
                    }
                    .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.6, brightness: 1.2, opacity: 0.25) ?? Color.white : Color(UIColor.systemGray6))
                    
                }
                
                
                Section {
                    Toggle("Favourite", isOn: $data[dataIndex].isFavourite)
                        .onChange(of: data[dataIndex].isFavourite) {
                            Task {
                                do {
                                    try await EventStore().save(events: data)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                        }
                    
                    Toggle("Mute", isOn: $data[dataIndex].isMuted)
                        .onChange(of: data[dataIndex].isMuted) {
                            Task {
                                do {
                                    try await EventStore().save(events: data)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                        }
                }
                .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                
                Section {
                    Button {
                        showConfirmationDialog = true
                        
                    } label: {
                        deleteButton
                        
                    }
                    .confirmationDialog(Text("Delete \"\(event.name ?? "Event")\" ?"),
                                        isPresented: $showConfirmationDialog,
                                        titleVisibility: .visible,
                                        actions: {
                        Button("Delete", role: .destructive) {
                            print("Delete Event")
                            
                            data.remove(at: dataIndex)
                            
                            Task {
                                do {
                                    try await EventStore().save(events: data)
                                    
                                } catch {
                                    fatalError(error.localizedDescription)
                                    
                                }
                            }
                            
                            presentationMode.wrappedValue.dismiss()
                            dismiss()
                            
                        }
                    },
                                        message: {
                        Text("This action cannot be undone")
                        
                    }
                    )
                }
                .listRowBackground(SettingsStore().listTinting ? event.averageColor(saturation: 0.5, brightness: 1, opacity: 0.08) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                
                
            }
            .background(.background)
            .scrollContentBackground(.hidden)
            .onAppear {
                if let index = data.firstIndex(where: { $0.id == eventID }) {
                    dataIndex = index
                    
                }
            }
            .onChange(of: data) {
                if let index = data.firstIndex(where: { $0.id == eventID }) {
                    dataIndex = index
                    
                } else {
                    // Event was deleted, dismiss the view
                    dismiss()
                    
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
                EditEventSheetView(data: $data, eventID: eventID)
                
            }
        } else {
            EmptyView()
                .onAppear {
                    dismiss()
                    
                }
        }
    }
    
    private func updateTimeUntilEvent() {
        guard let eventIndex = data.firstIndex(where: { $0.id == eventID }),
              eventIndex < data.count else {
            return
            
        }
        
        timeUntilEvent = calculateTime(event: data[eventIndex])
        
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
        
        return EventDetailView(data: previewEvents, eventID: previewEvents[0].id)
        
    }
}
