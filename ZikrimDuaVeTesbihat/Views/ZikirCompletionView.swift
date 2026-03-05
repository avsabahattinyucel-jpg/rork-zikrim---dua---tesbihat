import SwiftUI
import UIKit

private nonisolated enum CompletionStoryExport {
    static let size: CGSize = .init(width: 1080, height: 1920)
}

struct ZikirCompletionView: View {
    let counter: CounterModel
    let session: ZikrSession?
    let todayCount: Int
    let streak: Int
    let onRepeat: () -> Void
    let onNext: () -> Void
    let onGoHome: () -> Void
    let onDismiss: () -> Void

    @State private var showShareSheet: Bool = false
    @State private var renderedImage: UIImage?
    @State private var animateRing: Bool = false
    @State private var animateContent: Bool = false
    @State private var selectedStyle: CompletionCardStyle = .dark
    @State private var dragOffset: CGFloat = 0
    @State private var gemini = GroqService()
    @State private var zikirInsight: String? = nil
    @State private var isLoadingInsight: Bool = false
    @State private var aiHikmetNotu: String? = nil
    @State private var isGeneratingHikmet: Bool = false
    @State private var isPremium: Bool = false
    @State private var showAIAdAlert: Bool = false

    enum CompletionCardStyle: String, CaseIterable {
        case dark = "Koyu"
        case light = "Açık"
        case emerald = "Zümrüt"
        case gold = "Altın"

        var background: LinearGradient {
            switch self {
            case .dark:
                return LinearGradient(colors: [Color(red: 0.06, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.15, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .light:
                return LinearGradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.92), Color(red: 0.9, green: 0.9, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .emerald:
                return LinearGradient(colors: [Color(red: 0.02, green: 0.3, blue: 0.3), Color(red: 0.05, green: 0.45, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .gold:
                return LinearGradient(colors: [Color(red: 0.35, green: 0.25, blue: 0.05), Color(red: 0.5, green: 0.38, blue: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }

        var primaryText: Color {
            switch self {
            case .dark, .emerald, .gold: return .white
            case .light: return Color(red: 0.1, green: 0.1, blue: 0.15)
            }
        }

        var accentColor: Color {
            switch self {
            case .dark: return Color(red: 0.8, green: 0.72, blue: 0.45)
            case .light: return Color(red: 0.2, green: 0.5, blue: 0.45)
            case .emerald: return Color(red: 0.7, green: 0.92, blue: 0.8)
            case .gold: return Color(red: 0.98, green: 0.85, blue: 0.5)
            }
        }
    }

    private var titleText: String {
        session?.zikrTitle ?? counter.name
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                completionCard
                    .padding(.horizontal, 24)
                    .scaleEffect(animateContent ? 1 : 0.85)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: dragOffset)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? dragOffset : 20)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            withAnimation(.spring(duration: 0.3)) {
                                dragOffset = 600
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss()
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                animateContent = true
            }
            withAnimation(.easeInOut(duration: 1.0).delay(0.3).repeatForever(autoreverses: true)) {
                animateRing = true
            }
        }
        .task {
            isLoadingInsight = true
            let name = session?.zikrTitle ?? counter.name
            zikirInsight = try? await gemini.zikirSpiritualInsight(for: name)
            isLoadingInsight = false
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = renderedImage {
                ShareSheet(items: [img])
            }
        }
        .alert("Rabia Özelliği", isPresented: $showAIAdAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Premium ile Rabia'yı sınırsız kullanabilirsiniz. Ücretsiz kullanımda reklam gösterilir.")
        }
        .task {
            do {
                let info = try await RevenueCatService.shared.customerInfo()
                isPremium = RevenueCatService.shared.hasActiveEntitlement(info)
            } catch {}
        }
    }

    private var completionCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(selectedStyle.accentColor.opacity(0.2), lineWidth: 3)
                        .frame(width: animateRing ? 88 : 80, height: animateRing ? 88 : 80)

                    Circle()
                        .fill(selectedStyle.accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(selectedStyle.accentColor)
                }

                VStack(spacing: 6) {
                    Text("Tamamlandı")
                        .font(.caption.bold())
                        .foregroundStyle(selectedStyle.accentColor)
                        .textCase(.uppercase)
                        .kerning(1.5)

                    Text(titleText)
                        .font(.title.bold())
                        .foregroundStyle(selectedStyle.primaryText)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 20) {
                    statPill(value: "\(counter.targetCount)", label: "Tekrar", icon: "repeat")
                    statPill(value: "\(todayCount)", label: "Bugün", icon: "sun.max.fill")
                    statPill(value: "\(streak)", label: "Seri", icon: "flame.fill")
                }

                Divider()
                    .background(selectedStyle.accentColor.opacity(0.3))

                if let insight = zikirInsight {
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(selectedStyle.accentColor)
                            Text("MANEVİ DERİNLİK")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(selectedStyle.accentColor)
                                .tracking(0.8)
                        }
                        Text(insight)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(selectedStyle.primaryText.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .lineLimit(4)
                        Text("Bu içerik Rabia tarafından hazırlanmıştır.")
                            .font(.system(size: 9))
                            .foregroundStyle(selectedStyle.primaryText.opacity(0.3))
                    }
                    .padding(10)
                    .background(selectedStyle.accentColor.opacity(0.07))
                    .clipShape(.rect(cornerRadius: 10))
                } else if isLoadingInsight {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.55)
                            .tint(selectedStyle.accentColor)
                        Text("Manevi derinlik yükleniyor…")
                            .font(.system(size: 10))
                            .foregroundStyle(selectedStyle.primaryText.opacity(0.45))
                    }
                } else {
                    Text(spiritualMessage())
                        .font(.caption)
                        .italic()
                        .foregroundStyle(selectedStyle.primaryText.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                HStack {
                    Text(formattedDate())
                        .font(.caption2)
                        .foregroundStyle(selectedStyle.primaryText.opacity(0.5))
                    Spacer()
                    Text("Zikrim - Dua & Tesbihat")
                        .font(.caption2.bold())
                        .foregroundStyle(selectedStyle.accentColor)
                }

                stylePicker
            }
            .padding(24)
            .background(selectedStyle.background)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)

            Button {
                onDismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(12)
        }
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(selectedStyle.accentColor)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(selectedStyle.primaryText)
            Text(label)
                .font(.caption2)
                .foregroundStyle(selectedStyle.primaryText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(selectedStyle.accentColor.opacity(0.08))
        .clipShape(.rect(cornerRadius: 10))
    }

    private var stylePicker: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(CompletionCardStyle.allCases, id: \.self) { style in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedStyle = style
                            renderedImage = nil
                        }
                    } label: {
                        Circle()
                            .fill(style == .dark ? Color(red: 0.06, green: 0.1, blue: 0.2) :
                                  style == .light ? Color(red: 0.95, green: 0.93, blue: 0.88) :
                                  style == .emerald ? Color(red: 0.02, green: 0.35, blue: 0.35) :
                                  Color(red: 0.45, green: 0.32, blue: 0.06))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(selectedStyle == style ? Color.white : Color.clear, lineWidth: 2)
                            )
                    }
                }
                Spacer()
                Button {
                    renderAndShare()
                } label: {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedStyle.accentColor)
                        .foregroundStyle(.black)
                        .clipShape(.capsule)
                }
            }

            Button {
                enrichWithAI()
            } label: {
                if isGeneratingHikmet {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                            .tint(selectedStyle.accentColor)
                        Text("Hikmet Notu oluşturuluyor…")
                            .font(.caption.bold())
                            .foregroundStyle(selectedStyle.primaryText.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(selectedStyle.accentColor.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: aiHikmetNotu == nil ? "sparkles" : "checkmark.circle.fill")
                            .font(.caption.bold())
                        Text(aiHikmetNotu == nil ? "Rabia ile Zenginleştir" : "Hikmet Notu Eklendi ✓")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        aiHikmetNotu == nil
                            ? LinearGradient(colors: [Color.teal.opacity(0.15), Color.blue.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.green.opacity(0.15), Color.teal.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(aiHikmetNotu == nil ? selectedStyle.accentColor : .green)
                    .clipShape(.rect(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(selectedStyle.accentColor.opacity(0.25), lineWidth: 1)
                    )
                }
            }
            .disabled(isGeneratingHikmet)
        }
    }

    private func enrichWithAI() {
        if !isPremium {
            showAIAdAlert = true
            AdService.shared.showInterstitial()
        }

        Task {
            isGeneratingHikmet = true
            let title = session?.zikrTitle ?? counter.name
            let content = session?.meaning ?? session?.transliteration ?? ""
            aiHikmetNotu = try? await gemini.generateHikmetNotu(title: title, content: content)
            isGeneratingHikmet = false
            renderedImage = nil
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    onRepeat()
                } label: {
                    Label("Tekrar Et", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground).opacity(0.9))
                        .foregroundStyle(.primary)
                        .clipShape(.rect(cornerRadius: 14))
                }

                Button {
                    onNext()
                } label: {
                    Label("Sonraki", systemImage: "forward.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground).opacity(0.9))
                        .foregroundStyle(.primary)
                        .clipShape(.rect(cornerRadius: 14))
                }
            }

            Button {
                if let image = renderedImage {
                    showShareSheet = true
                } else {
                    renderAndShare()
                }
            } label: {
                Label("Paylaş", systemImage: "square.and.arrow.up")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(.rect(cornerRadius: 12))
            }

            Button {
                onGoHome()
            } label: {
                Label("Ana Sayfaya Dön", systemImage: "house.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 14))
            }
        }
    }

    @MainActor
    private func renderAndShare() {
        let cardContent = shareableCard
            .frame(width: CompletionStoryExport.size.width, height: CompletionStoryExport.size.height)

        let renderer = ImageRenderer(content: cardContent)
        renderer.scale = 1.0
        if let img = renderer.uiImage {
            renderedImage = img
            showShareSheet = true
        }
    }

    private var shareableCard: some View {
        ZStack {
            selectedStyle.background
            VStack(spacing: 0) {
                Spacer(minLength: 220)

                if let session {
                    Text(session.arabicText)
                        .font(.system(size: 56, weight: .semibold))
                        .lineSpacing(16)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.4)
                        .foregroundStyle(selectedStyle.primaryText)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 28)
                }

                Text(titleText)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .foregroundStyle(selectedStyle.primaryText)
                    .padding(.horizontal, 40)

                Text(session?.meaning ?? spiritualMessage())
                    .font(.system(size: 28, weight: .medium))
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .foregroundStyle(selectedStyle.primaryText.opacity(0.8))
                    .padding(.top, 22)
                    .padding(.horizontal, 60)

                if let hikmet = aiHikmetNotu {
                    Text("✶ \(hikmet)")
                        .font(.system(size: 26, weight: .medium, design: .serif))
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .foregroundStyle(selectedStyle.accentColor)
                        .padding(.top, 14)
                        .padding(.horizontal, 60)
                        .italic()
                }

                Spacer(minLength: 180)

                HStack(spacing: 34) {
                    statColumn(value: "\(counter.targetCount)", label: "Tekrar")
                    statColumn(value: "\(todayCount)", label: "Bugün")
                    statColumn(value: "\(streak)", label: "Seri")
                }

                Text(formattedDate())
                    .font(.system(size: 18))
                    .foregroundStyle(selectedStyle.primaryText.opacity(0.55))
                    .padding(.top, 28)

                Text("Zikrim - Dua & Tesbihat")
                    .font(.system(size: 38, weight: .bold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(selectedStyle.accentColor)
                    .padding(.horizontal, 60)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
            }
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 7) {
            Text(value)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(selectedStyle.primaryText)
            Text(label)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(selectedStyle.primaryText.opacity(0.7))
        }
    }

    private func spiritualMessage() -> String {
        let messages = [
            "\"Allah'ı çokça zikredin ki kurtuluşa eresiniz.\" (Cuma 10)",
            "\"Kalpler ancak Allah'ın zikriyle huzur bulur.\" (Ra'd 28)",
            "\"Kim Allah'ı çokça zikrederse onu sever.\" (Hadis)",
            "\"Zikir, kalbin gıdasıdır.\"",
            "\"Her tespihin karşılığı bir ağaç dikilmesidir.\" (Hadis)"
        ]
        return messages[abs(counter.name.hashValue) % messages.count]
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM yyyy, HH:mm"
        return formatter.string(from: Date())
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
