import SwiftUI
import CoreLocation

struct QiblaView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var qiblaService = QiblaService()
    @State private var wasAligned: Bool = false

    private let gold = Color(red: 0.88, green: 0.74, blue: 0.42)
    private let emerald = Color(red: 0.16, green: 0.76, blue: 0.58)
    private let deepNavy = Color(red: 0.03, green: 0.05, blue: 0.11)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                    .ignoresSafeArea()

                content
            }
            .navigationTitle(L10n.string(.kibleBulucu))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                }
            }
            .onAppear {
                if qiblaService.authorizationStatus == .authorizedWhenInUse || qiblaService.authorizationStatus == .authorizedAlways {
                    qiblaService.startUpdates()
                }
            }
            .onDisappear {
                qiblaService.stopUpdates()
            }
            .onChange(of: isAligned) { oldValue, newValue in
                if newValue && !oldValue {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    wasAligned = true
                } else if !newValue && oldValue {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    wasAligned = false
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if qiblaService.authorizationStatus == .notDetermined {
            permissionView
        } else if qiblaService.authorizationStatus == .denied || qiblaService.authorizationStatus == .restricted {
            deniedView
        } else if qiblaService.userLocation == nil {
            loadingView
        } else {
            compassExperience
        }
    }

    private var backgroundView: some View {
        AtmosphericBackgroundView(
            baseColors: [
                deepNavy,
                Color(red: 0.06, green: 0.08, blue: 0.16),
                Color(red: 0.02, green: 0.03, blue: 0.08)
            ],
            primaryGlow: gold,
            secondaryGlow: emerald,
            overlayTint: Color.white.opacity(0.03),
            isDarkMode: true,
            primaryAlignment: .topTrailing,
            secondaryAlignment: .bottomLeading,
            primaryOffsetRatio: CGSize(width: 0.18, height: -0.20),
            secondaryOffsetRatio: CGSize(width: -0.18, height: 0.20),
            glowIntensity: isAligned ? 1.14 : 0.96
        )
    }

    private var permissionView: some View {
        VStack(spacing: 24) {
            Spacer()

            statusOrb(icon: "location.fill", tint: emerald)

            VStack(spacing: 8) {
                Text(.konumIzniGerekli)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(.kibleYonunuHesaplayabilmekIcinNkonumunuzaErismemizGerekiyor)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            Button {
                qiblaService.requestPermission()
            } label: {
                Text(.konumuEtkinlestir)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(emerald)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var deniedView: some View {
        VStack(spacing: 24) {
            Spacer()

            statusOrb(icon: "location.slash.fill", tint: .orange)

            VStack(spacing: 8) {
                Text(.konumIzniKapali)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(.kibleBulucuIcinKonumIzniniNayarlarDanEtkinlestirin)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(.ayarlariAc)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var loadingView: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
                .tint(gold)
            Text(.konumAliniyor)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
            Spacer()
        }
    }

    private var compassExperience: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                headerCard

                HStack(spacing: 12) {
                    metricCard(title: L10n.string(.yonunuz), value: degreeText(qiblaService.heading), accent: .white)
                    metricCard(title: L10n.string(.kible2), value: degreeText(qiblaService.qiblaBearing), accent: gold)
                    metricCard(title: "Sapma", value: degreeText(alignmentDelta), accent: isAligned ? emerald : .white)
                }

                compassCard

                guidanceCard

                if let error = qiblaService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                if !qiblaService.isHeadingAvailable {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(.pusulaBuCihazdaKullanilamiyor)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isAligned)
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gold.opacity(0.34), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 44
                        )
                    )
                    .frame(width: 84, height: 84)

                Image("QiblaKaaba")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(gold.opacity(0.55), lineWidth: 1.5)
                    )
                    .shadow(color: gold.opacity(0.25), radius: 16, x: 0, y: 8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(.kabeIMuazzama)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)

                Text(.mekkeSuudiArabistan2)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))

                if qiblaService.distanceToKaabaKM > 0 {
                    labelChip(text: L10n.format(.distanceKmFormat, Int64(qiblaService.distanceToKaabaKM)), tint: emerald)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(18)
        .background(cardBackground)
    }

    private var compassCard: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
                    )

                VStack(spacing: 18) {
                    compassDial

                    if isAligned {
                        labelChip(text: L10n.string(.kibleYonundesiniz), tint: emerald)
                    } else {
                        labelChip(text: "Altın çizgiyi kıbleyle hizalayın", tint: gold)
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var compassDial: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 310, height: 310)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 310, height: 310)

            Circle()
                .stroke(isAligned ? emerald.opacity(0.55) : gold.opacity(0.32), lineWidth: 2)
                .frame(width: 264, height: 264)
                .shadow(color: isAligned ? emerald.opacity(0.22) : gold.opacity(0.18), radius: 18)

            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                .frame(width: 220, height: 220)

            compassTicks
                .rotationEffect(.degrees(-qiblaService.heading))
                .animation(.interpolatingSpring(stiffness: 70, damping: 14), value: qiblaService.heading)

            alignmentBeam
                .rotationEffect(.degrees(qiblaService.qiblaDirection))
                .animation(.interpolatingSpring(stiffness: 90, damping: 16), value: qiblaService.qiblaDirection)

            VStack(spacing: 0) {
                Image(systemName: "triangle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .rotationEffect(.degrees(180))

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.85), .white.opacity(0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 56)
            }
            .offset(y: -108)

            ZStack {
                Circle()
                    .fill(deepNavy)
                    .frame(width: 84, height: 84)

                Circle()
                    .stroke(isAligned ? emerald.opacity(0.55) : gold.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 84, height: 84)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                VStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(isAligned ? emerald : gold)
                    Text(verbatim: degreeText(alignmentDelta))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
        }
        .frame(width: 310, height: 310)
    }

    private var compassTicks: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { index in
                let isMajor = index.isMultiple(of: 18)
                let isMid = index.isMultiple(of: 9)

                Rectangle()
                    .fill(Color.white.opacity(isMajor ? 0.62 : isMid ? 0.30 : 0.12))
                    .frame(width: isMajor ? 2 : 1, height: isMajor ? 18 : isMid ? 11 : 6)
                    .offset(y: -150)
                    .rotationEffect(.degrees(Double(index) * 5))
            }

            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 3) ? gold.opacity(0.65) : Color.white.opacity(0.24))
                    .frame(width: index.isMultiple(of: 3) ? 5 : 3, height: index.isMultiple(of: 3) ? 5 : 3)
                    .offset(y: -132)
                    .rotationEffect(.degrees(Double(index) * 30))
            }
        }
    }

    private var alignmentBeam: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(gold.opacity(0.20))
                    .frame(width: 42, height: 42)
                    .blur(radius: 10)

                Text(verbatim: "🕋")
                    .font(.system(size: 26))
                    .shadow(color: gold.opacity(0.35), radius: 10)
            }

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [gold.opacity(0.95), gold.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6, height: 92)
                .overlay(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1.4, height: 92)
                )
        }
        .offset(y: -96)
    }

    private var guidanceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: isAligned ? "checkmark.seal.fill" : "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isAligned ? emerald : gold)
                .frame(width: 36, height: 36)
                .background((isAligned ? emerald : gold).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(isAligned ? L10n.string(.kibleYonundesiniz) : L10n.string(.moreQiblaSubtitle))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                Text(qiblaService.isSyncingRemoteBearing ? "Yön bilgisi Aladhan API ile yenileniyor." : "Telefonun üst kısmını altın işaretle aynı hizada tutun.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
            }

            Spacer()
        }
        .padding(16)
        .background(cardBackground)
    }

    private func statusOrb(icon: String, tint: Color) -> some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.12))
                .frame(width: 126, height: 126)
            Circle()
                .stroke(tint.opacity(0.28), lineWidth: 1)
                .frame(width: 102, height: 102)
            Image(systemName: icon)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(tint)
        }
    }

    private func metricCard(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .kerning(1.1)
                .foregroundStyle(.white.opacity(0.46))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(verbatim: value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(cardBackground)
    }

    private func labelChip(text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(verbatim: text)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(tint.opacity(0.28), lineWidth: 1)
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private var alignmentDelta: Double {
        let normalized = qiblaService.qiblaDirection
        return min(normalized, 360 - normalized)
    }

    private var isAligned: Bool {
        alignmentDelta <= 4.5
    }

    private func degreeText(_ value: Double) -> String {
        L10n.format(.degreesFormat, Int64(value.rounded()))
    }
}
