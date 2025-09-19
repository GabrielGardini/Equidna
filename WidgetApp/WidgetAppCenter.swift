//
//  WidgetAppCenter.swift
//  WidgetEquidna
//
//  Created by Gabriel Rugeri on 02/09/25.
//

import WidgetKit
import SwiftUI
import AppIntents
import CloudKit


let contactsPlaceholder: [String] = ["Gabriel Gardini", "Camille Luppi", "Rodrigo Cont", "Gabriel Rugeri"]

// MARK: - Provider (TimelineProvider)
struct AssetEntry: TimelineEntry {
    let date: Date
    let assets: [AssetInfo]
    let selectedIndex: Int = 0
}

struct ThumbnailDisplay: Identifiable {
    let id: String
    let friend: String
    let image: UIImage
}


struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AssetEntry {
        AssetEntry(date: Date(), assets: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (AssetEntry) -> ()) {
        let assets = loadCachedAssets()
        completion(AssetEntry(date: Date(), assets: assets))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AssetEntry>) -> ()) {
        let assets = loadCachedAssets()
        let entry = AssetEntry(date: Date(), assets: assets)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}


// MARK: - Widget Views
struct EquidnaWidgetEntryView: View {
    var entry: AssetEntry
    var maxImages: Int = 4
    var showContacts: Bool = false

    var body: some View {
        GeometryReader { geo in
            if showContacts {
                // MEDIUM 2x4 — 50/50 (esquerda imagem, direita lista tocável)
                HStack(spacing: 0) {
                    // Escolhe a mídia conforme seleção
                    let imageToShow = entry.assets[safe: entry.selectedIndex]?.thumbnailImage ?? entry.assets.first?.thumbnailImage
                    MediaPane(image: imageToShow)
                        .frame(width: geo.size.width * 0.5, height: geo.size.height)

                    ContactListView(
                        contacts: entry.assets.compactMap(\.friend),
                        maxItems: maxImages,
                        selectedIndex: entry.selectedIndex
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.height, alignment: .topLeading)
                }
                .frame(width: geo.size.width, height: geo.size.height)

            } else {
                // SMALL 2x2 — imagem full + INICIAIS no topo esquerdo
                ZStack(alignment: .topLeading) {
                    let imageToShow = entry.assets[safe: entry.selectedIndex]?.thumbnailImage ?? entry.assets.first?.thumbnailImage
                    MediaPane(image: imageToShow)
                        .frame(width: geo.size.width, height: geo.size.height)

                    // Iniciais do contato selecionado (ou do primeiro)
                    let friends = entry.assets.compactMap(\.friend)
                    let selectedName = friends[safe: entry.selectedIndex] ?? friends.first ?? ""
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
                    .fill(Color.indigo.opacity(0.9))
                    .frame(width: 36, height: 36)
            )
    }
}

// MARK: - Helpers
func loadCachedAssets() -> [AssetInfo] {
    let defaults = UserDefaults(suiteName: appGroupID)
    
    guard let data = defaults?.data(forKey: keyOnAssets) else {
        print("⚠️ Nenhum cache encontrado")
        return []
    }
    
    let decoder = JSONDecoder()
    if let assets = try? decoder.decode([AssetInfo].self, from: data) {
        print("✅ Carregado \(assets.count) assets do cache")
        return assets
    } else {
        print("⚠️ Falha ao decodificar AssetInfo")
        return []
    }
}

/// Carrega thumbnails do App Group e retorna modelo de exibição
func loadThumbnailDisplays() -> [ThumbnailDisplay] {
    let assets = loadCachedAssets()
    
    let displays: [ThumbnailDisplay] = assets.compactMap { asset in
        guard let path = asset.thumbnailPath,
              let image = UIImage(contentsOfFile: path) else { return nil }
        return ThumbnailDisplay(id: asset.id, friend: asset.friend, image: image)
    }
    
    if !displays.isEmpty {
        return displays
    }
    
    // Fallback: thumbnails de cores com nomes genéricos
    func solid(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    let fallbackColors: [UIColor] = [.red, .green, .blue, .yellow]
    return fallbackColors.enumerated().map { index, color in
        ThumbnailDisplay(id: "\(index)", friend: "Friend \(index + 1)", image: solid(color))
    }
}


func loadSelectedIndex() -> Int {
    let defaults = UserDefaults(suiteName: appGroupID)
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
    AssetEntry(date: .now, assets: loadCachedAssets())
}

#Preview(as: .systemMedium) {
    WidgetMedium()
} timeline: {
    AssetEntry(date: .now, assets: loadCachedAssets())
}
