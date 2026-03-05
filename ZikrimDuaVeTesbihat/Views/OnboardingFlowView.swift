import SwiftUI

struct OnboardingFlowView: View {
    let authService: AuthService
    let onFinish: () -> Void

    @State private var selection: Int = 0
    @State private var showPaywall: Bool = false
    @State private var notificationService = NotificationService()
    @State private var pageTransitionTick: Int = 0
    @State private var rabiaWelcomeVisible: Bool = false
    @State private var rabiaMessage: String = "Esselâmü aleyküm, ben Rabia. Bu uygulamada zikirlerini düzenli takip etmen, dualarını güçlendirmen ve günlük ibadet ritmini huzurla sürdürmen için sana adım adım eşlik edeceğim."
    @State private var rabiaMessageSymbol: String = "sparkles"
    @State private var rabiaMessageTitle: String = "Rabia'dan hoş geldin"
    @State private var rabiaMessageMood: Double = 0

    private let rabiaMessages: [String] = [
        "Esselâmü aleyküm, ben Rabia. Bu uygulamada zikirlerini düzenli takip etmen, günlük dualarını ihmal etmeden sürdürmen ve manevi hayatını daha istikrarlı hale getirmen için sana rehber olacağım. Niyetini taze tut, küçük adımları bereketli bir düzene birlikte dönüştürelim.",
        "Bugün az da olsa devamlı bir zikirle başlayalım. Bu uygulama sana günün duasını, manevi tavsiyeleri ve hatırlatmaları tek yerde sunarak kalbini diri tutmana yardımcı olur. Düzenli ibadet, istikrar ve iç huzur için birlikte ilerleyelim inşallah.",
        "Her gün aynı kararlılıkla devam etmek, manevi yolculuğun en güçlü tarafıdır. Burada namaz takibini, zikir hedeflerini, günlük notlarını ve Rabia'nın rehberliğini bir arada bulacaksın. Allah niyetini hayra çevirsin, istikametini kuvvetlendirsin."
    ]

    private let rabiaTitles: [String] = [
        "Rabia'dan hoş geldin",
        "Rabia'dan günlük motivasyon",
        "Rabia'dan son dokunuş"
    ]

    private let rabiaSymbols: [String] = [
        "sparkles",
        "heart.text.square.fill",
        "moon.stars.fill"
    ]

    private func pageDistance(for index: Int) -> CGFloat {
        CGFloat(selection - index)
    }

    private func updateRabiaSection(for index: Int) {
        let safeIndex: Int = max(0, min(index, rabiaMessages.count - 1))
        rabiaMessage = rabiaMessages[safeIndex]
        rabiaMessageTitle = rabiaTitles[safeIndex]
        rabiaMessageSymbol = rabiaSymbols[safeIndex]
    }

    private func rabiaMessageCard(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(rabiaMessageTitle, systemImage: rabiaMessageSymbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(rabiaMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.blue.opacity(0.18), lineWidth: 1)
        }
        .padding(.horizontal, 20)
        .opacity(rabiaWelcomeVisible ? 1 : 0.45)
        .scaleEffect(rabiaWelcomeVisible ? 1 : 0.96)
        .offset(y: rabiaWelcomeVisible ? 0 : 6)
        .animation(.smooth(duration: 0.35), value: rabiaWelcomeVisible)
        .phaseAnimator([0.0, 1.0], trigger: pageTransitionTick) { content, phase in
            content
                .offset(y: phase == 0 ? 4 : 0)
                .opacity(phase == 0 ? 0.9 : 1)
        } animation: { _ in
            .snappy(duration: 0.32)
        }
        .sensoryFeedback(.selection, trigger: pageTransitionTick)
    }

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Zikir Sayacı",
            subtitle: "Hedef belirleyin, zikrinizi düzenli takip edin ve serinizi koruyun.",
            symbol: "circle.circle.fill",
            imageURL: URL(string: "https://r2-pub.rork.com/generated-images/53782945-bbce-4f3c-9a7e-fd969e299a7a.png")
        ),
        OnboardingPage(
            title: "Günlük Dua & Rabia",
            subtitle: "Rabia ile günlük dua, zikir takibi, manevi rehberlik ve akıllı hatırlatmalarla istikrarlı bir ibadet rutini oluşturun.",
            symbol: "sparkles",
            imageURL: URL(string: "https://r2-pub.rork.com/generated-images/ae6ca04e-4372-415e-9b6f-fc717810b197.png")
        ),
        OnboardingPage(
            title: "Premium Avantajlar",
            subtitle: "Aylık ₺79 veya yıllık ₺799 ile reklamsız kullanım, gelişmiş istatistik, widget ve bulut senkronizasyonunu açın.",
            symbol: "crown.fill",
            imageURL: URL(string: "https://r2-pub.rork.com/generated-images/66d70d26-bb7e-4a28-b746-978ea3f2a174.png")
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()

                            Color(.secondarySystemBackground)
                                .frame(height: 230)
                                .overlay {
                                    if let imageURL: URL = page.imageURL {
                                        AsyncImage(url: imageURL) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .offset(x: pageDistance(for: index) * 18)
                                                    .allowsHitTesting(false)
                                            case .failure:
                                                Image(systemName: page.symbol)
                                                    .font(.system(size: 56))
                                                    .foregroundStyle(.secondary)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                                .clipShape(.rect(cornerRadius: 22))
                                .overlay {
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.0),
                                            Color.black.opacity(0.14),
                                            Color.black.opacity(0.32)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .allowsHitTesting(false)
                                }
                                .overlay(alignment: .topLeading) {
                                    Image(systemName: page.symbol)
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(.ultraThinMaterial)
                                        .clipShape(.rect(cornerRadius: 12))
                                        .padding(12)
                                }
                                .padding(.horizontal, 20)
                                .scaleEffect(selection == index ? 1 : 0.985)
                                .animation(.smooth(duration: 0.35), value: selection)

                            VStack(spacing: 10) {
                                Text(page.title)
                                    .font(.title.bold())
                                    .multilineTextAlignment(.center)
                                Text(page.subtitle)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 24)
                            .phaseAnimator([false, true], trigger: pageTransitionTick) { content, phase in
                                content
                                    .offset(y: phase ? 0 : 7)
                                    .opacity(phase ? 1 : 0.85)
                            } animation: { _ in
                                .snappy(duration: 0.3)
                            }

                            if index == selection {
                                rabiaMessageCard(for: index)
                            }

                            if index == 2 {
                                VStack(spacing: 8) {
                                    Label("Aylık plan: ₺79 / ay", systemImage: "checkmark.seal.fill")
                                    Label("Yıllık plan: ₺799 / yıl", systemImage: "checkmark.seal.fill")
                                    Label("Yıllık alımda 3 gün ücretsiz deneme", systemImage: "sparkles")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 14))
                                .padding(.horizontal, 20)
                            }

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .onAppear {
                    updateRabiaSection(for: selection)
                    withAnimation(.smooth(duration: 0.35)) {
                        rabiaWelcomeVisible = true
                    }
                }
                .onChange(of: selection) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    pageTransitionTick += 1
                    rabiaWelcomeVisible = false
                    updateRabiaSection(for: newValue)
                    rabiaMessageMood = Double(newValue)
                    withAnimation(.snappy(duration: 0.34)) {
                        rabiaWelcomeVisible = true
                    }
                }

                VStack(spacing: 10) {
                    Button {
                        if selection == 1 {
                            Task {
                                await notificationService.requestAuthorization()
                                await notificationService.checkAuthorization()
                                if notificationService.isAuthorized {
                                    notificationService.smartNotificationsEnabled = true
                                    notificationService.scheduleSmartNotifications()
                                }
                            }
                        }

                        if selection < pages.count - 1 {
                            withAnimation(.spring(duration: 0.3)) {
                                selection += 1
                            }
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Text(selection == pages.count - 1 ? "Premium'i Gör" : "Devam")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button("Atla") {
                        onFinish()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPaywall, onDismiss: onFinish) {
                PremiumView(authService: authService)
            }
        }
    }
}

nonisolated struct OnboardingPage: Sendable {
    let title: String
    let subtitle: String
    let symbol: String
    let imageURL: URL?
}
