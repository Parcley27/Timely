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
        let navigationTitleWrapper = data[dataIndex].name ?? "EventName"
        
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text(data[dataIndex].name ?? "EventName")
                            .font(.title)
                            .bold()
                        
                        Text(timeUntilEvent)
                            .onAppear {
                                updateTimeUntilEvent()
                                
                            }
                            .font(.title3)
                            .foregroundStyle(data[dataIndex].hasPassed ? .red : .primary)
                            .bold(data[dataIndex].hasPassed)
                        
                    }
                    
                    Spacer()
                    
                    Text(data[dataIndex].emoji ?? "📅")
                        .font(.system(size: 42))
                }
            }
            .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.13) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
            
            Section {
                HStack {
                    Text(data[dataIndex].dateString ?? "Event date and time")
                        .foregroundStyle(data[dataIndex].hasPassed ? .red : .primary)
                        .bold(data[dataIndex].hasStarted)
                    
                }
            }
            .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.11) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
            
            
            if data[dataIndex].description != nil {
                Section {
                    Text(data[dataIndex].description ?? "")
                    
                }
                .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                
            }
            
            if data[dataIndex].isCopy ?? false {
                if let sourceEvent = data.firstIndex(where: { $0.id == data[dataIndex].copyOfEventWithID }) {
                    Section {
                        NavigationLink(destination: EventDetailView(data: $data, eventID: data[sourceEvent].id)) {
                            Text("View Original Event")
                            
                        }
                        .bold()
                        .foregroundStyle(.selection)
                        
                    }
                    .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
                    
                }
                
                let totalCopies = data.filter { $0.copyOfEventWithID == data[dataIndex].copyOfEventWithID }
                
                Section {
                    Text("Copy \(data[dataIndex].copyNumber ?? 0) of \(totalCopies.count), repeating \(NSLocalizedString(data[dataIndex].recurranceRate!, comment: ""))")
                    
                }
                .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color.white : Color.secondary)
                
            }
            
            
            Section {
                Toggle("Favourite", isOn: $data[dataIndex].isFavourite)
                    .onChange(of: data[dataIndex].isFavourite) { newValue in
                        Task {
                            do {
                                try await EventStore().save(events: data)
                                
                            } catch {
                                fatalError(error.localizedDescription)
                                
                            }
                        }
                    }
                
                Toggle("Mute", isOn: $data[dataIndex].isMuted)
                    .onChange(of: data[dataIndex].isMuted) { newValue in
                        Task {
                            do {
                                try await EventStore().save(events: data)
                                
                            } catch {
                                fatalError(error.localizedDescription)
                                
                            }
                        }
                    }
            }
            .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.09) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))
            
            Section {
                Button {
                    showConfirmationDialog = true
                    
                } label: {
                    deleteButton
                    
                }
                .confirmationDialog(Text("Delete \"\(data[dataIndex].name!)\" ?"),
                    isPresented: $showConfirmationDialog,
                    titleVisibility: .visible,
                    actions: {
                        Button("Delete", role: .destructive) {
                            print("Delete Event")
                                                        
                            presentationMode.wrappedValue.dismiss()
                            dismiss()
                            
                            data.remove(at: dataIndex)
                            
                        }
                    },
                    message: {
                        Text("This action cannot be undone")
                    
                    }
                )
            }
            .listRowBackground(SettingsStore().listTinting ? data[dataIndex].averageColor(saturation: 0.5, brightness: 1, opacity: 0.08) ?? Color(UIColor.systemGray6) : Color(UIColor.systemGray6))

            
        }
        .onAppear {
            dataIndex = data.firstIndex(where: { $0.id == eventID })!
            
        }
        .onChange(of: data) { _ in
            dataIndex = data.firstIndex(where: { $0.id == eventID })!
            
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
            EditEventSheetView(data: $data, event: dataIndex)
            
        }
    }
    
    private func updateTimeUntilEvent() {
        timeUntilEvent = calculateTime(event: data[data.firstIndex(where: { $0.id == eventID })!])
        
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
