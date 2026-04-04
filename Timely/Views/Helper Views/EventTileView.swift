//
//  EventTileView.swift
//  Timely
//
//  Created by Pierce Oxley on 4/4/26.
//

import SwiftUI

struct EventTileView: View {
    @EnvironmentObject var preferences: SettingsStore
    @EnvironmentObject var eventStore: EventStore
    
    var event: Event
    
    init(for event: Event) {
        self.event = event
        
    }
    
    var body: some View {
        ZStack {
            NavigationLink(destination: EventDetailView(data: $eventStore.events, eventID: event.id)) {
                HStack(spacing: 12) {
                    // Emoji icon
                    Text(event.emoji ?? "📅")
                        .font(.system(size: 40))
                        .padding(2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Event name
                        Text(event.name ?? "Event Name")
                            .font(.headline)
                            .fontWeight(.semibold)
                        //.font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        
                        // Time until
                        Text(event.timeUntil)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                    }
                    //.shadow(color: Color.black, radius: 20)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if event.isPinned ?? false {
                            StatusIconView(.pinned, Color.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                            
                        }
                        
                        if event.isFavourite {
                            StatusIconView(.favourite, Color.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                        }
                        
                        if event.isMuted {
                            StatusIconView(.muted, Color.gray)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                            
                        }
                    }
                    .padding(.vertical, 3)
                    .saturation(1.15)
                    //.font(.caption)
                    .font(.system(size: 13))
                    .brightness(preferences.listTinting ? 0.1 : 0) // -1 ... 1
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .brightness(0.2) // -1 ... 1
                    
                }
                .padding(16)
                .background(
                    TileView(inputColours: event.averageColour() ?? Color(.systemGray6))
                    
                )
                
            }
            .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: 24))
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .contextMenu() {
                if preferences.allowContextMenu {
                    Button {
                        //togglePin(for: event.id)
                        
                    } label: {
                        if event.isPinned ?? false {
                            Label("Unpin", systemImage: "pin.slash")
                            
                        } else {
                            Label("Pin", systemImage: "pin")
                            
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        //toggleFavourite(for: event.id)
                        
                    } label: {
                        if event.isFavourite {
                            Label("Unfavourite", systemImage: "star.slash")
                            
                        } else {
                            Label("Favourite", systemImage: "star")
                            
                        }
                    }
                    
                    Button {
                        //toggleMuted(for: event.id)
                        
                    } label: {
                        if event.isMuted {
                            Label("Unmute", systemImage: "bell")
                            
                        } else {
                            Label("Mute", systemImage: "bell.slash")
                            
                        }
                    }
                    
                    Divider()
                    
                    NavigationLink(destination: EventDetailView(data: $eventStore.events, eventID: event.id, showEditEventSheet: true)) {
                        Label("Edit", systemImage: "slider.horizontal.3")
                        
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        //deleteEvent(with: event.id)
                        
                    } label: {
                        Label("Delete \"\(event.name ?? "Event Name")\"", systemImage: "trash")
                        
                    }
                }
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    
    let dummyEvent: Event = Event(name: "Sample Event 1", emoji: "🌲", dateAndTime: Date(), endDateAndTime: calendar.date(byAdding: .minute, value: 30, to: Date()))
    
    EventTileView(for: dummyEvent)
    
}
