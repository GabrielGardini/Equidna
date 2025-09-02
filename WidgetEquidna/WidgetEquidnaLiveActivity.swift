//
//  WidgetEquidnaLiveActivity.swift
//  WidgetEquidna
//
//  Created by Gabriel Rugeri on 02/09/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetEquidnaAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WidgetEquidnaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetEquidnaAttributes.self) { context in
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

extension WidgetEquidnaAttributes {
    fileprivate static var preview: WidgetEquidnaAttributes {
        WidgetEquidnaAttributes(name: "World")
    }
}

extension WidgetEquidnaAttributes.ContentState {
    fileprivate static var smiley: WidgetEquidnaAttributes.ContentState {
        WidgetEquidnaAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WidgetEquidnaAttributes.ContentState {
         WidgetEquidnaAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WidgetEquidnaAttributes.preview) {
   WidgetEquidnaLiveActivity()
} contentStates: {
    WidgetEquidnaAttributes.ContentState.smiley
    WidgetEquidnaAttributes.ContentState.starEyes
}
