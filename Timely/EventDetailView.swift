//
//  EventDetailView.swift
//  Timely
//
//  Created by Pierce Oxley on 2023-08-06.
//

import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject var data: EventData
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var event: Event
        
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            //let navigationTitleWrapper = (event.emoji ?? "📅") + " " + (event.name ?? "Event Name")
            let navigationTitleWrapper = (event.name ?? "Details")
            
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(event.name ?? "Event Name")
                                .font(.title)
                                .bold()
                            Text(event.timeUntil + timeUpdater)
                                .onReceive(timer) { _ in
                                    timeUpdater = " "
                                    timeUpdater = ""
                                }
                                .foregroundStyle(event.timeUntil.hasPrefix("-") == true ? .red : .primary)
                                .bold(event.timeUntil.hasPrefix("-") == true)
                        }
                        
                        Spacer()
                        
                        Text(event.emoji ?? "📅")
                            .font(.system(size: 42))
                    }
                }
                
                Section {
                    HStack {
                        Text(event.dateString ?? "Event date and time")
                            .foregroundStyle(event.timeUntil.hasPrefix("-") == true ? .red : .primary)
                            .bold(event.timeUntil.hasPrefix("-") == true)
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
                            data.toggleFavouriteEvent(event: event)
                        }
                    
                    Toggle("Mute", isOn: $event.isMuted)
                        .onChange(of: event.isMuted) { newValue in
                            data.toggleMutedEvent(event: event)
                        }
                }

                Section {
                    Button {
                        confirmationIsShowing = true
                    } label: {
                        deleteButton
                    }
                        .actionSheet(isPresented: $confirmationIsShowing) {
                            ActionSheet(
                                title: Text("This action can not be undone"),
                                buttons: [
                                    .cancel(Text("Cancel")),
                                    .destructive(Text("Delete Event"), action: {
                                        data.removeEvent(event:event)
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
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .navigationBarTitle(navigationTitleWrapper, displayMode: .inline)
        }
    }
}

struct EventDetailViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event"),
        ]

        return EventDetailView(event: previewData.events[0])
               .environmentObject(previewData)
    }
}
