//
//  WidgetEquidnaBundle.swift
//  WidgetEquidna
//
//  Created by Gabriel Rugeri on 02/09/25.
//

import WidgetKit
import SwiftUI

@main
struct WidgetEquidnaBundle: WidgetBundle {
    var body: some Widget {
        WidgetSmall()
        WidgetMedium()
        WidgetEquidnaControl()
        WidgetEquidnaLiveActivity()
    }
}
