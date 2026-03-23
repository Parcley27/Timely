//
//  TimelyWidgetBundle.swift
//  TimelyWidget
//
//  Created by Pierce Oxley on 23/3/26.
//

import WidgetKit
import SwiftUI

@main
struct TimelyWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimelyWidget()
        TimelyWidgetControl()
        TimelyWidgetLiveActivity()
    }
}
