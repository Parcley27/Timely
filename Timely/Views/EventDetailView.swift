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
        
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showEditEventSheet = false
    @State private var confirmationIsShowing = false
    
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
                        .bold(data[event].hasPassed)
                }
            }
            
            if data[event].description != nil {
                Section {
                    Text(data[event].description ?? "")
                    
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
                    confirmationIsShowing = true
                    
                } label: {
                    deleteButton
                    
                }
                .alert(Text("Delete \(data[event].name!)?"),
                    isPresented: $confirmationIsShowing,
                    actions: {
                    Button("Delete", role: .destructive) {
                        print("dele")
                        
                        data.remove(at: event)
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Button("Cancel", role: .cancel) {}
                    }, message: {
                        Text("This action cannot be undone")
                    })
                    .actionSheet(isPresented: $confirmationIsShowing) {
                        ActionSheet(
                            title: Text("This action can not be undone"),
                            buttons: [
                                .cancel(Text("Cancel")),
                                .destructive(Text("Delete Event"), action: {
                                    //data.removeEvent(event:event)
                                    presentationMode.wrappedValue.dismiss()
                                })
                            ]
                        )
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Edit event")
                    showEditEventSheet = true
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                    
                }
            }
        }
        .navigationBarTitle(navigationTitleWrapper, displayMode: .inline)
        .sheet(isPresented: $showEditEventSheet) {
            EditEventSheetView(data: $data, event: event)
            
        }
    }
    
    @State private var timeUntilEvent: String = ""

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
