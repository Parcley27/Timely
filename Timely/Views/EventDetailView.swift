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
    @EnvironmentObject var preferences: SettingsStore
    @EnvironmentObject var eventStore: EventStore
    
    @Environment(\.colorScheme) var colorScheme
    var isLightMode: Bool { colorScheme == .light }
    
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
        if let event = currentEvent {
            //let navigationTitleWrapper = event.name ?? "Event Name"
            
            ZStack {
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.5),
                            .init(color: event.averageColour(saturation: 0.7) ?? Color(.blue), location: 0.9)
                            
                        ]),
                        
                        startPoint: .bottom,
                        endPoint: .top
                        
                    )
                    .opacity(0.7)
                    .ignoresSafeArea(.all)
                    
                    Spacer()
                    
                }
                
                EmojiSplashView(emoji: event.emoji ?? "📅", colour: event.averageColour(saturation: 0.5) ?? Color(.blue), size: 50, height: 5, width: 5)
                    .offset(y: -450)
                
                NoiseView()
                
                VStack {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(height: 100)
                    
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text(event.emoji ?? "📅")
                                    .font(.system(size: 80))
                                
                                Text(event.name ?? "Event Name")
                                    .font(.largeTitle)
                                    .bold()
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                            .padding(.top, 24)
                            
                            VStack(spacing: 4) {
                                if !event.hasStarted {
                                    Text("Starting in")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                }
                                
                                Text(timeUntilEvent)
                                    .onAppear {
                                        updateTimeUntilEvent()
                                        
                                    }
                                    .font(.system(size: 32, weight: .bold))
                                    .multilineTextAlignment(.center)
                                
                                if event.hasStarted {
                                    Text(event.hasPassed ? "ago" : "remaining")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        
                                }
                                
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date and Time")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Text(event.dateString ?? "Event date and time")
                                    .font(.system(size: 16, weight: .medium))
                                    .bold(event.hasStarted && !event.hasPassed)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                            
                            if event.description != nil {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text(event.description ?? "")
                                        .font(.body)
                                    
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                    
                                )
                                
                            }
                            
                            if event.isCopy ?? false {
                                if let sourceEvent = data.firstIndex(where: { $0.id == event.copyOfEventWithID }) {
                                    VStack {
                                        NavigationLink(destination: EventDetailView(data: $data, eventID: data[sourceEvent].id)) {
                                            Text("View Original Event")
                                            
                                        }
                                        .bold()
                                        .foregroundStyle(.selection)
                                        
                                        let totalCopies = data.filter { $0.copyOfEventWithID == event.copyOfEventWithID }
                                        
                                        Text("Copy \(event.copyNumber ?? 0) of \(totalCopies.count), repeating \(NSLocalizedString(event.recurranceRate ?? "never", comment: ""))")
                                        
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Urgency")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
                                Toggle("Favourite", isOn: $data[dataIndex].isFavourite)
                                    .onChange(of: data[dataIndex].isFavourite) {
                                        Task {
                                            do {
                                                try await eventStore.save(events: data)
                                                
                                            } catch {
                                                eventStore.saveError = error
                                                
                                            }
                                        }
                                    }
                                
                                Divider()
                                
                                Toggle("Mute", isOn: $data[dataIndex].isMuted)
                                    .onChange(of: data[dataIndex].isMuted) {
                                        Task {
                                            do {
                                                try await eventStore.save(events: data)
                                                
                                            } catch {
                                                eventStore.saveError = error
                                                
                                            }
                                        }
                                    }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                            
                            Button {
                                showConfirmationDialog = true
                                
                                Toggle("Pin to Top", isOn: Binding(
                                    get: { data[dataIndex].isPinned ?? false },
                                    set: { data[dataIndex].isPinned = $0 }
                                    
                                ))
                                
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Danger Zone")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                
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
                                                try await eventStore.save(events: data)
                                                
                                            } catch {
                                                eventStore.saveError = error
                                                
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
                            .padding()
                            .background(
                                TileView(inputColours: event.averageColour() ?? Color(.blue), forceBackground: true, saturationModifier: 0.75, customBorder: false)
                                
                            )
                        }
                        .padding()
                        
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    
                    .background(
                        TileView(inputColours: event.averageColour(saturation: 0.1, brightness: 1.3) ?? Color(.systemGray6), forceBackground: true, cornerRadius: 36)
                        
                    )
                    
                    .padding()
                    
                }
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
            //.navigationBarTitle(navigationTitleWrapper, displayMode: .inline)
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
        let previewPreferences = SettingsStore()
        let previewData = EventData()
        let calendar = Calendar.current
        
        previewData.events = [
            Event(name: "Sample Event", emoji: "📅", description: "Multi-line description so that text spacing can be properly tested in the view :)", dateAndTime: calendar.date(byAdding: .day, value: 7, to: Date())!, endDateAndTime: calendar.date(byAdding: .day, value: 8, to: Date()), isFavourite: true)
            
        ]
        
        let previewEvents = Binding.constant(previewData.events)
        let previewStore = EventStore()
        previewStore.events = previewData.events
        
        return NavigationStack {
            EventDetailView(data: previewEvents, eventID: previewEvents[0].id)
                .environmentObject(previewPreferences)
                .environmentObject(previewStore)
            
        }
    }
}

