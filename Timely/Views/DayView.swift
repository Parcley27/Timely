//
//  DayView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-04-19.
//

import SwiftUI

struct DayView: View {
    @Binding var data: [Event]
    let event: Int
    
    let saveAction: () -> Void
        
    @Environment(\.presentationMode) private var presentationMode
    
    /*
    @State private var timeUpdater: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    */
    
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
        //NavigationStack {
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
                                    // Update the time until event initially
                                    updateTimeUntilEvent()
                                }
                                //.onReceive(timer) { _ in
                                  //  timeUpdater = " "
                                    //timeUpdater = ""
                                //}
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
                            //data.toggleFavouriteEvent(event: event)
                            saveAction()
                        }
                    
                    Toggle("Mute", isOn: $data[event].isMuted)
                        .onChange(of: data[event].isMuted) { newValue in
                            //data.toggleMutedEvent(event: event)
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
                //EditEventSheetView(data: $data, event: $event)
            }
        //}
    }
    
    @State private var timeUntilEvent: String = ""

    private func updateTimeUntilEvent() {
        // Function to compute the time until event
        timeUntilEvent = calculateTime(event: data[event])
        
        // Schedule the next update
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateTimeUntilEvent() // Recur every second
        }
    }
}

struct DayViewPreviews: PreviewProvider {
    static var previews: some View {
        let previewData = EventData()
        previewData.events = [
            Event(name: "Sample Event 1", dateAndTime: Date()),
            Event(name: "Sample Event 2", isMuted: true),
            Event(name: "Sample Event 3", isFavourite: true)
            // Add more sample events if needed
        ]
        
        let previewEvents = Binding.constant(previewData.events)

        return DayView(data: previewEvents, event: 1, saveAction: {})
    }
}
