//
//  Untitled.swift
//  Equidna
//
//  Created by Rodrigo Cont on 04/09/25.
//

import AppIntents
import WidgetKit

@available(iOSApplicationExtension 17.0, *)

struct SelectContactIntent: AppIntent {
    static var title: LocalizedStringResource = "Selecionar contato"

    @Parameter(title: "Index")
    var index: Int

    init() {}
    init(index: Int) { self.index = index }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.Gardinidev.EquidnaApp")
        defaults?.set(max( 0, index), forKey: "selectedIndex")

        // Recarrega os widgets envolvidos
        WidgetCenter.shared.reloadTimelines(ofKind: "WidgetEquidnaSmall")
        WidgetCenter.shared.reloadTimelines(ofKind: "WidgetEquidnaMedium")

        return .result()
    }
}



