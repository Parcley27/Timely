//
//  CalendarView.swift
//  Timely
//
//  Created by Pierce Oxley on 2024-03-25.
//

import SwiftUI

struct SlidingMonthContainer: View {
    @Binding var displayMonth: Int
    @Binding var displayYear: Int
    @Binding var data: [Event]
    
    let isLightMode: Bool
    let saveAction: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isDragging = false
    
    var minDistance = CGFloat(100)
    
    private var previousMonth: Int { displayMonth == 1 ? 12 : displayMonth - 1 }
    private var previousYear: Int { displayMonth == 1 ? displayYear - 1 : displayYear }
    private var nextMonth: Int { displayMonth == 12 ? 1 : displayMonth + 1 }
    private var nextYear: Int { displayMonth == 12 ? displayYear + 1 : displayYear }
    
    var body: some View {
        TabView(selection: $displayMonth) {
            MonthGridView(month: previousMonth, year: previousYear, data: $data, isLightMode: isLightMode, isDragging: isDragging, saveAction: saveAction)
                .tag(previousMonth)
            
            MonthGridView(month: displayMonth, year: displayYear, data: $data, isLightMode: isLightMode, isDragging: isDragging, saveAction: saveAction)
                .tag(displayMonth)
            
            MonthGridView(month: nextMonth, year: nextYear, data: $data, isLightMode: isLightMode, isDragging: isDragging, saveAction: saveAction)
                .tag(nextMonth)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        
    }
}

struct CalendarView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var preferences: SettingsStore
    
    @Environment(\.colorScheme) var colorScheme
    var isLightMode: Bool { colorScheme == .light }
    
    @Binding var data: [Event]
    
    @State var displayMonth: Int
    @State var displayYear: Int
    
    let saveAction: () -> Void
    
    @State private var showingSettings: Bool = false
    
    let columnLayout = Array(repeating: GridItem(spacing: 5, alignment: .center), count: 7)
    
    var currentMonth = Calendar.current.component(.month, from: Date())
    var currentYear = Calendar.current.component(.year, from: Date())
    
    var dayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        guard let daySymbols = formatter.shortWeekdaySymbols else { return [""] }
        
        let firstWeekday = Calendar.current.firstWeekday - 1
        
        return Array(daySymbols[firstWeekday...] + daySymbols[..<firstWeekday])
        
    }
    
    var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if let monthComponents = formatter.monthSymbols {
            return monthComponents
            
        }
        
        return [""]
        
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLightMode && preferences.showFilmGrain {
                    NoiseView()
                    
                }
                
                VStack {
                    // Month navigation bar
                    HStack {
                        Button {
                            if displayMonth == 1 {
                                displayMonth = 12
                                displayYear -= 1
                                
                            } else {
                                displayMonth -= 1
                                
                            }
                            
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        Button("\(monthNames[displayMonth - 1]) \(String(displayYear))") {
                            displayMonth = currentMonth
                            displayYear = currentYear
                            
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button {
                            if displayMonth == 12 {
                                displayMonth = 1
                                displayYear += 1
                                
                            } else {
                                displayMonth += 1
                                
                            }
                            
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                        }
                        .padding(.trailing, 16)
                        
                    }
                    .padding(.vertical, 12)
                    .background(
                        TileView(inputColours: .accentColor, forceBackground: true, saturationModifier: 0.6, customBorder: true, isLightMode: isLightMode)
                        
                    )
                    .glassEffect(.regular.tint(.clear).interactive(), in: .rect(cornerRadius: 24))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    // Day name headers
                    LazyVGrid(columns: columnLayout) {
                        ForEach(dayNames, id: \.self) { name in
                            Text(name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // Calendar grid
                    SlidingMonthContainer(
                        displayMonth: $displayMonth,
                        displayYear: $displayYear,
                        data: $data,
                        isLightMode: isLightMode,
                        saveAction: {
                            Task {
                                do {
                                    try await eventStore.save(events: eventStore.events)
                                    
                                } catch {
                                    eventStore.saveError = error
                                    
                                }
                            }
                        }
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettings = true
                            
                        } label: {
                            Image(systemName: "gearshape")
                            
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                    
                }
                .navigationBarTitle("Calendar")
                
            }
        }
    }
}

#Preview {
    let previewPreferences = SettingsStore()

    let previewData = EventData()
    previewData.events = [
        Event(name: "Sample Event 1", dateAndTime: Date()),
        Event(name: "Sample Event 2", isMuted: true),
        Event(name: "Sample Event 3", isFavourite: true)
        
    ]
    
    let previewEvents = Binding.constant(previewData.events)
    
    let currentMonth = Calendar.current.component(.month, from: Date())
    let currentYear = Calendar.current.component(.year, from: Date())
    
    return CalendarView(data: previewEvents, displayMonth: currentMonth, displayYear: currentYear, saveAction: {})
        .environmentObject(previewPreferences)
    
}
