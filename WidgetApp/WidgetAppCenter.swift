//
//  WidgetAppCenter.swift
//  WidgetEquidna
//
//  Created by Gabriel Rugeri on 02/09/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - TimelineEntry
struct EquidnaEntry: TimelineEntry {
    let date: Date
    let images: [UIImage]
    let contacts: [String]
    let selectedIndex: Int
}

// MARK: - Provider (TimelineProvider)
struct Provider: TimelineProvider {
    // Atualização a cada N horas
    let refreshFrequency: Int = 6

    func placeholder(in context: Context) -> EquidnaEntry {
        EquidnaEntry(
            date: Date(),
            images: loadLatestPhotos(),
            contacts: loadContactsPlaceholder(),
            selectedIndex: loadSelectedIndex()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EquidnaEntry) -> Void) {
        let images = loadLatestPhotos()
        let contacts = loadContactsPlaceholder()
        let selected = loadSelectedIndex()
        completion(EquidnaEntry(date: Date(), images: images, contacts: contacts, selectedIndex: selected))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquidnaEntry>) -> Void) {
        let images = loadLatestPhotos()
        let contacts = loadContactsPlaceholder()
        let selected = loadSelectedIndex()

        let entry = EquidnaEntry(date: Date(), images: images, contacts: contacts, selectedIndex: selected)
        let refreshDate = Calendar.current.date(byAdding: .hour, value: refreshFrequency, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Widget Views
struct EquidnaWidgetEntryView: View {
    var entry: EquidnaEntry
    var maxImages: Int = 4
    var showContacts: Bool = false

    var body: some View {
        GeometryReader { geo in
            if showContacts {
                // MEDIUM 2x4 — 50/50 (esquerda imagem, direita lista tocável)
                HStack(spacing: 0) {
                    // Escolhe a mídia conforme seleção
                    let imageToShow = entry.images[safe: entry.selectedIndex] ?? entry.images.first
                    MediaPane(image: imageToShow)
                        .frame(width: geo.size.width * 0.5, height: geo.size.height)

                    ContactListView(
                        contacts: entry.contacts,
                        maxItems: maxImages,
                        selectedIndex: entry.selectedIndex
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.height, alignment: .topLeading)
                }
                .frame(width: geo.size.width, height: geo.size.height)

            } else {
                // SMALL 2x2 — imagem full + INICIAIS no topo esquerdo
                ZStack(alignment: .topLeading) {
                    let imageToShow = entry.images[safe: entry.selectedIndex] ?? entry.images.first
                    MediaPane(image: imageToShow)
                        .frame(width: geo.size.width, height: geo.size.height)

                    // Iniciais do contato selecionado (ou do primeiro)
                    let selectedName = entry.contacts[safe: entry.selectedIndex] ?? entry.contacts.first ?? ""
                    let initials = makeInitials(from: selectedName)

                    Badge(initials: initials)
                        .padding(8)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: - Subviews
private struct MediaPane: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                Rectangle().fill(Color.red) // imagem de teste/fallback
            }
        }
    }
}

private struct ContactListView: View {
    let contacts: [String]
    let maxItems: Int
    let selectedIndex: Int

    private let rowHeight: CGFloat = 39.5

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let count = min(maxItems, contacts.count)

            ForEach(0..<count, id: \.self) { idx in
                Button(intent: SelectContactIntent(index: idx)) {
                    HStack(spacing: 8) {
                        Text(contacts[idx]) // 2x4 mantém NOME COMPLETO
                            .font(.callout) // SF Pro dinâmico
                            .fontWeight(idx == selectedIndex ? .semibold : .regular)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .frame(height: rowHeight)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle()) // facilita o toque
                    .background(
                        (idx == selectedIndex ? Color.secondary.opacity(0.12) : .clear) // highlight sutil
                    )
                }
                .buttonStyle(.plain)

                if idx < count - 1 {
                    Divider()
                }
            }
            Spacer(minLength: 0)
        }
        .background(Color.clear) // full-bleed na metade direita
    }
}

private struct Badge: View {
    let initials: String
    var body: some View {
        Text(initials)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Circle()
                    .fill(Color.blue.opacity(0.9))
                    .frame(width: 36, height: 36)
            )
    }
}

// MARK: - Helpers

/// Carrega fotos do App Group (ou gera 4 cores de teste)
func loadLatestPhotos() -> [UIImage] {
    let defaults = UserDefaults(suiteName: "group.Gardinidev.EquidnaApp")
    if let datas = defaults?.array(forKey: "latestPhotoDatas") as? [Data], !datas.isEmpty {
        return datas.compactMap { UIImage(data: $0) }
    }
    // Fallback de teste: 4 cores
    func solid(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    return [ solid(.red), solid(.green), solid(.blue), solid(.yellow) ]
}

/// Placeholder de contatos (substitua quando for integrar com dados reais)
func loadContactsPlaceholder() -> [String] {
    ["Gabriel Gardini", "Camille Luppi", "Rodrigo Cont", "Gabriel Rugeri"]
}

func loadSelectedIndex() -> Int {
    let defaults = UserDefaults(suiteName: "group.Gardinidev.EquidnaApp")
    return defaults?.integer(forKey: "selectedIndex") ?? 0
}

/// Gera iniciais (ex.: "Gabriel Gardini" -> "GG"; "Ana" -> "A")
func makeInitials(from name: String) -> String {
    let parts = name
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: .whitespaces)
        .filter { !$0.isEmpty }

    guard let firstWord = parts.first, let f = firstWord.first else { return "?" }
    let second: Character? = (parts.count > 1) ? parts.last?.first : nil

    let s1 = String(f).uppercased()
    let s2 = second.map { String($0).uppercased() } ?? ""
    return s1 + s2
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Widgets

// SMALL 2x2
struct WidgetSmall: Widget {
    let kind: String = "WidgetEquidnaSmall"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EquidnaWidgetEntryView(entry: entry, maxImages: 2, showContacts: false)
                .containerBackground(Color.clear, for: .widget)
        }
        .contentMarginsDisabled() // iOS 17+
        .configurationDisplayName("Mais recente")
        .description("Tenha acesso rápido à última mídia recebida.")
        .supportedFamilies([.systemSmall])
    }
}

// MEDIUM 2x4
struct WidgetMedium: Widget {
    let kind: String = "WidgetEquidnaMedium"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            EquidnaWidgetEntryView(entry: entry, maxImages: 4, showContacts: true)
                .containerBackground(Color.clear, for: .widget)
        }
        .contentMarginsDisabled() // iOS 17+
        .configurationDisplayName("Lista dos últimos recebidos")
        .description("Tenha acesso rápido às últimas mídias recebidas.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    WidgetSmall()
} timeline: {
    EquidnaEntry(date: .now, images: loadLatestPhotos(), contacts: loadContactsPlaceholder(), selectedIndex: 0)
}

#Preview(as: .systemMedium) {
    WidgetMedium()
} timeline: {
    EquidnaEntry(date: .now, images: loadLatestPhotos(), contacts: loadContactsPlaceholder(), selectedIndex: 1)
}
