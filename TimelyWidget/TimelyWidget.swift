//
//  TimelyWidget.swift
//  TimelyWidget
//
//  Created by Pierce Oxley on 23/3/26.
//

import WidgetKit
import SwiftUI

struct EventEntry: TimelineEntry {
    let date: Date
    let nextEvent: Event? // Event sets widget config
    
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> EventEntry {
        //SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
        EventEntry(date: Date(), nextEvent: Event(name: "Next Event", emoji: "📅"))
        
    }
    
//    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: configuration)
//
//    }
    
    func getSnapshot(in context: Context, completion: @escaping (EventEntry) -> Void) {
        let next = SharedEventStore.load()
            .filter { !$0.hasPassed }
            .sorted { $0.dateAndTime < $1.dateAndTime }
            .first
        
        completion(EventEntry(date: Date(), nextEvent: next))
        
    }
    
//    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
//        var entries: [SimpleEntry] = []
//        
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
//        
//        return Timeline(entries: entries, policy: .atEnd)
//    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<EventEntry>) -> Void) {
        let next = SharedEventStore.load()
            .filter { !$0.hasPassed }
            .sorted { $0.dateAndTime < $1.dateAndTime }
            .first
        
        let entry = EventEntry(date: Date(), nextEvent: next)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30)))
        
        completion(timeline)
        
    }
    
//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct TimelyWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        if let event = entry.nextEvent {
            ZStack {
                EmojiSplashView(emoji: event.emoji ?? "📅", colour: event.averageColour() ?? .red)
                    .scaleEffect(0.5)
                    .offset(x: -10, y: -170)
                
                NoiseView()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name ?? "Event")
                        .font(.headline)
                        .bold()
                    
                    Text(event.dateAndTime, style: .date)
                        .font(.subheadline)
                        .bold()
                    
                }
                .offset(x: -16)
                .padding()
                .padding(.horizontal, 200)
                .background(
                    Color(event.averageColour() ?? .purple).adjusted(saturation: 0.5)
                
                )
                .offset(y: 48)
                
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(event.averageColour() ?? .purple).adjusted(saturation: 0.2)
//                TileView(inputColours: event.averageColour() ?? .black, forceBackground: true, customBorder: true, cornerRadius: 28)
//                    .frame(minWidth: 164, minHeight: 164)
                
            )
            //.glassEffect(.regular.tint(.clear), in: .rect(cornerRadius: 24))
            
        } else {
            Text("No Upcoming Events")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
        }
    }
}

struct TimelyWidget: Widget {
    let kind: String = "TimelyWidget"
    
    var body: some WidgetConfiguration {
//        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
//            TimelyWidgetEntryView(entry: entry)
//                .containerBackground(.fill.tertiary, for: .widget)
//            
//        }
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimelyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        
        }
        .configurationDisplayName("Next Event")
        .description("Shows your next upcoming event.")
        .supportedFamilies([.systemSmall, .systemMedium])
        
    }
}

//extension ConfigurationAppIntent {
//    fileprivate static var smiley: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
//        return intent
//        
//    }
//    
//    fileprivate static var starEyes: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
//        return intent
//        
//    }
//}

#Preview(as: .systemSmall) {
    TimelyWidget()
    
} timeline: {
    EventEntry(date: .now, nextEvent: Event(name: "Hiking Trip", emoji: "🏔️", dateAndTime: Date().addingTimeInterval(7200)))
    EventEntry(date: .now, nextEvent: nil)
    
}

#Preview(as: .systemMedium) {
    TimelyWidget()
    
} timeline: {
    EventEntry(date: .now, nextEvent: Event(name: "Hiking Trip", emoji: "🏔️", dateAndTime: Date().addingTimeInterval(7200)))
    EventEntry(date: .now, nextEvent: nil)
    
}
