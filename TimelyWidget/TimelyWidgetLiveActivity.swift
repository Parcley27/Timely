//
//  TimelyWidgetLiveActivity.swift
//  TimelyWidget
//
//  Created by Pierce Oxley on 23/3/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimelyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TimelyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimelyWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimelyWidgetAttributes {
    fileprivate static var preview: TimelyWidgetAttributes {
        TimelyWidgetAttributes(name: "World")
    }
}

extension TimelyWidgetAttributes.ContentState {
    fileprivate static var smiley: TimelyWidgetAttributes.ContentState {
        TimelyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TimelyWidgetAttributes.ContentState {
         TimelyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TimelyWidgetAttributes.preview) {
   TimelyWidgetLiveActivity()
} contentStates: {
    TimelyWidgetAttributes.ContentState.smiley
    TimelyWidgetAttributes.ContentState.starEyes
}
