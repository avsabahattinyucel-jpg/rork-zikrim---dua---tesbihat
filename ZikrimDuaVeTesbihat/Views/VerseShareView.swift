import SwiftUI
import UIKit

private nonisolated enum StoryExport {
    static let size: CGSize = .init(width: 1080, height: 1920)
}

struct VerseShareView: View {
    let verse: QuranVerse
    let surahName: String
    let surahArabicName: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedStyle: CardStyle = .dark
    @State private var shareMode: QuranDisplayMode = .both
    @State private var renderedImage: UIImage?
    @State private var isRendering: Bool = false
    @State private var showShareSheet: Bool = false

    enum CardStyle: String, CaseIterable {
        case dark = "Koyu"
        case light = "Açık"
        case teal = "Zümrüt"
        case sand = "Kum"

        var background: LinearGradient {
            switch self {
            case .dark:
                return LinearGradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.18), Color(red: 0.1, green: 0.15, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .light:
                return LinearGradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.93), Color(red: 0.89, green: 0.87, blue: 0.82)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .teal:
                return LinearGradient(colors: [Color(red: 0.04, green: 0.35, blue: 0.35), Color(red: 0.08, green: 0.55, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .sand:
                return LinearGradient(colors: [Color(red: 0.85, green: 0.78, blue: 0.65), Color(red: 0.73, green: 0.65, blue: 0.52)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        var primaryText: Color {
            switch self {
            case .dark, .teal: return .white
            case .light, .sand: return Color(red: 0.1, green: 0.1, blue: 0.1)
            }
        }

        var secondaryText: Color {
            switch self {
            case .dark, .teal: return Color.white.opacity(0.78)
            case .light, .sand: return Color.black.opacity(0.64)
            }
        }

        var accentColor: Color {
            switch self {
            case .dark: return Color(red: 0.8, green: 0.7, blue: 0.4)
            case .light: return Color(red: 0.15, green: 0.5, blue: 0.5)
            case .teal: return Color(red: 0.8, green: 0.9, blue: 0.85)
            case .sand: return Color(red: 0.45, green: 0.3, blue: 0.15)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    verseCard(style: selectedStyle)
                        .frame(height: 560)
                        .clipShape(.rect(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 20)

                    styleSelector
                    shareButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ayet Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    private var styleSelector: some View {
        VStack(spacing: 12) {
            Text("Stil")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CardStyle.allCases, id: \.self) { style in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                selectedStyle = style
                                renderedImage = nil
                            }
                        } label: {
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(style.background)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedStyle == style ? Color.accentColor : Color.clear, lineWidth: 2.5)
                                    )
                                Text(style.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(selectedStyle == style ? .primary : .secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Picker("İçerik", selection: $shareMode) {
                ForEach(QuranDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .onChange(of: shareMode) { _, _ in renderedImage = nil }
        }
    }

    private func verseCard(style: CardStyle) -> some View {
        ZStack {
            style.background
            VStack(spacing: 0) {
                Spacer(minLength: 210)

                if shareMode == .both || shareMode == .arabicOnly {
                    Text(verse.arabicText)
                        .font(.system(size: 52, weight: .semibold))
                        .lineSpacing(16)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.42)
                        .foregroundStyle(style.primaryText)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, 36)
                }

                if shareMode == .both || shareMode == .turkishOnly {
                    Text(verse.turkishTranslation)
                        .font(.system(size: 24, weight: .medium))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineSpacing(6)
                        .foregroundStyle(style.secondaryText)
                        .padding(.horizontal, 40)
                        .padding(.top, 18)
                }

                Spacer(minLength: 160)

                Text("\(surahName) • \(verse.verseNumber). Ayet")
                    .font(.headline)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(style.accentColor)
                    .padding(.horizontal, 24)

                Text(surahArabicName)
                    .font(.title3)
                    .foregroundStyle(style.secondaryText)
                    .padding(.top, 4)

                Text("Zikrim - Dua & Tesbihat")
                    .font(.system(size: 38, weight: .bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(style.secondaryText.opacity(0.9))
                    .padding(.horizontal, 60)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
            }
        }
    }

    private var shareButtons: some View {
        VStack(spacing: 12) {
            if let image = renderedImage {
                Button {
                    showShareSheet = true
                } label: {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                } label: {
                    Label("Galeriye Kaydet", systemImage: "photo.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 14))
                }
            } else {
                Button {
                    renderCard()
                } label: {
                    Group {
                        if isRendering {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Label("Kart Oluştur", systemImage: "wand.and.sparkles")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
                }
                .disabled(isRendering)
            }
        }
    }

    @MainActor
    private func renderCard() {
        isRendering = true
        let cardView = verseCard(style: selectedStyle)
            .frame(width: StoryExport.size.width, height: StoryExport.size.height)
            .clipShape(.rect(cornerRadius: 0))

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1.0
        if let uiImage = renderer.uiImage {
            renderedImage = uiImage
        }
        isRendering = false
    }

}
