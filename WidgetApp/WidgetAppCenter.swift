//
//  WidgetEquidna.swift
//  WidgetEquidna
//
//  Created by Gabriel Rugeri on 02/09/25.
//

import WidgetKit
import SwiftUI

struct EquidnaEntry: TimelineEntry {
    let date: Date
    let images: [UIImage]
}

struct Provider: TimelineProvider {
    // Tempo (em horas) de atualização
    let refreshFrequency: Int = 6
    
    func placeholder(in context: Context) -> EquidnaEntry {
            EquidnaEntry(date: Date(), images: [])
        }

    func getSnapshot(in context: Context, completion: @escaping (EquidnaEntry) -> Void) {
        let images = loadLatestPhotos()
        completion(EquidnaEntry(date: Date(), images: images))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquidnaEntry>) -> Void) {
        let images = loadLatestPhotos()
        let entry = EquidnaEntry(date: Date(), images: images)

        let refreshDate = Calendar.current.date(byAdding: .hour, value: refreshFrequency, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadEntry() -> EquidnaEntry {
        let defaults = UserDefaults(suiteName: "group.Gardinidev.EquidnaApp")
        let datas = defaults?.array(forKey: "latestPhotoDatas") as? [Data] ?? []
        let images = datas.compactMap { UIImage(data: $0) }
        return EquidnaEntry(date: Date(), images: images)
    }
}


struct EquidnaWidgetEntryView: View {
    var entry: EquidnaEntry
    var maxImages: Int = 4

    var body: some View {
        HStack(spacing: 4) {
            ForEach(entry.images.prefix(maxImages), id: \.self) { img in
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            }
        }
    }
}

// MARK: - Funções auxiliares
func loadLatestPhotos() -> [UIImage] {
    let defaults = UserDefaults(suiteName: "group.Gardinidev.EquidnaApp")

    guard let datas = defaults?.array(forKey: "latestPhotoDatas") as? [Data] else {
        return []
    }

    return datas.compactMap { UIImage(data: $0) }
}


// MARK: - Widget pequeno (2x2)
struct WidgetSmall: Widget {
    let kind: String = "WidgetEquidnaSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                EquidnaWidgetEntryView(entry: entry, maxImages: 2)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                EquidnaWidgetEntryView(entry: entry, maxImages: 2)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Equidna Widget Pequeno")
        .description("Mostra até 2 das últimas fotos recebidas.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Widget médio (2x4)
struct WidgetMedium: Widget {
    let kind: String = "WidgetEquidnaMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                EquidnaWidgetEntryView(entry: entry, maxImages: 4)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                EquidnaWidgetEntryView(entry: entry, maxImages: 4)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Equidna Widget Médio")
        .description("Mostra até 4 das últimas fotos recebidas.")
        .supportedFamilies([.systemMedium])
    }
}



// MARK: - Preview
#Preview(as: .systemSmall) {
    WidgetSmall()
} timeline: {
    EquidnaEntry(date: .now, images: [])
    EquidnaEntry(date: .now.addingTimeInterval(60), images: [])
}
