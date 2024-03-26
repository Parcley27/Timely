//
//  EventDetailView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-06.
//

import SwiftUI

struct EventDetailView: View {
    @Binding var data: [Event]
    @Binding var event: Event
        
    @Environment(\.presentationMode) var presentationMode
        
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
    
    var body: some View {
        NavigationStack {
            // Alternate navigation bar title
            //let navigationTitleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
            let navigationTitleWrapper = (event.name ?? "Details")
            
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(event.name ?? "Event Name")
                                .font(.title)
                                .bold()
                            Text(event.timeUntil)
                                .onReceive(timer) { _ in
                                    timeUpdater = " "
                                    timeUpdater = ""
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
                
                Section {
                    HStack {
                        Text(event.dateString ?? "Event date and time")
                            .foregroundStyle(event.hasPassed ? .red : .primary)
                            .bold(event.hasPassed)
                    }
                }
                
                if event.description != nil {
                    Section {
                        Text(event.description ?? "")
                    }
                }
                
                Section {
                    Toggle("Favourite", isOn: $event.isFavourite)
                        .onChange(of: event.isFavourite) { newValue in
                            //data.toggleFavouriteEvent(event: event)
                        }
                    
                    Toggle("Mute", isOn: $event.isMuted)
                        .onChange(of: event.isMuted) { newValue in
                            //data.toggleMutedEvent(event: event)
                        }
                }

                Section {
                    Button {
                        confirmationIsShowing = true
                    } label: {
                        deleteButton
                    }
                    .alert(Text("Delete \(event.name!)?"),
                        isPresented: $confirmationIsShowing,
                        actions: {
                        Button("Delete", role: .destructive) {
                            print("dele")
                            if let index = $data.firstIndex(where: { $0.id == event.id }) {
                                data.remove(at: index)
                                //saveAction()
                                print("hee")
                                presentationMode.wrappedValue.dismiss()

                            }
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
                EditEventSheetView(data: $data, event: $event)
            }
        }
    }
}

struct EventDetailViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
        ]

        // Create a binding to the events array in previewData
        let previewEvents = Binding.constant(previewData.events)

        return EventDetailView(data: previewEvents, event: Binding.constant(previewData.events[0]))
    }
}
