import SwiftUI
import CoreLocation

struct QiblaView: View {
    @State private var qiblaService = QiblaService()
    @State private var isPremium: Bool = false
    @State private var wasAligned: Bool = false

    private let emerald = Color(red: 0.15, green: 0.82, blue: 0.56)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if qiblaService.authorizationStatus == .notDetermined {
                        permissionView
                    } else if qiblaService.authorizationStatus == .denied || qiblaService.authorizationStatus == .restricted {
                        deniedView
                    } else if qiblaService.userLocation == nil {
                        loadingView
                    } else {
                        compassView
                    }
                }
            }
            .navigationTitle("Kıble Bulucu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if qiblaService.authorizationStatus == .authorizedWhenInUse || qiblaService.authorizationStatus == .authorizedAlways {
                    qiblaService.startUpdates()
                }
            }
            .onDisappear {
                qiblaService.stopUpdates()
            }
            .task {
                do { let info = try await RevenueCatService.shared.customerInfo(); isPremium = RevenueCatService.shared.hasActiveEntitlement(info) } catch {}
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
            .safeAreaInset(edge: .bottom) {
                ConditionalBannerAd(isPremium: isPremium)
            }
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.12)
            RadialGradient(
                colors: [
                    Color(red: 0.06, green: 0.18, blue: 0.22).opacity(0.6),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            if isAligned {
                RadialGradient(
                    colors: [emerald.opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 300
                )
                .animation(.easeInOut(duration: 0.6), value: isAligned)
            }
        }
    }

    private var permissionView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(emerald.opacity(0.1))
                    .frame(width: 120, height: 120)
                Circle()
                    .stroke(emerald.opacity(0.3), lineWidth: 1)
                    .frame(width: 100, height: 100)
                Image(systemName: "location.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(emerald)
            }

            VStack(spacing: 8) {
                Text("Konum İzni Gerekli")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Kıble yönünü hesaplayabilmek için\nkonumunuza erişmemiz gerekiyor.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                qiblaService.requestPermission()
            } label: {
                Text("Konumu Etkinleştir")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(emerald)
            .padding(.horizontal, 48)
            Spacer()
        }
    }

    private var deniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.red.opacity(0.8))
            }

            VStack(spacing: 8) {
                Text("Konum İzni Kapalı")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Kıble bulucu için konum iznini\nAyarlar'dan etkinleştirin.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Ayarları Aç")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 48)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(emerald)
            Text("Konum alınıyor...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
        }
    }

    private var compassView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                kaabaCard

                bearingInfo

                compassDial

                alignmentIndicator

                if let error = qiblaService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if !qiblaService.isHeadingAvailable {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Pusula bu cihazda kullanılamıyor")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .animation(.spring(duration: 0.4), value: isAligned)
    }

    private var bearingInfo: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("YÖNÜNÜZ")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                Text("\(Int(qiblaService.heading))°")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1, height: 36)

            VStack(spacing: 4) {
                Text("KIBLE")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(emerald.opacity(0.8))
                Text("\(Int(qiblaService.qiblaBearing))°")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(emerald)
            }

            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(width: 1, height: 36)

            VStack(spacing: 4) {
                Text("YÖN")
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                Text(bearingToCardinal(qiblaService.qiblaBearing))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var compassDial: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.02))
                .frame(width: 300, height: 300)

            if isAligned {
                Circle()
                    .fill(emerald.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 20)

                Circle()
                    .stroke(emerald.opacity(0.3), lineWidth: 2)
                    .frame(width: 300, height: 300)
                    .shadow(color: emerald.opacity(0.5), radius: 12)
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 300, height: 300)
            }

            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                .frame(width: 230, height: 230)

            Group {
                ForEach(0..<72, id: \.self) { i in
                    let isMajor = i % 18 == 0
                    let isMinorMajor = i % 9 == 0
                    Rectangle()
                        .fill(Color.white.opacity(isMajor ? 0.6 : isMinorMajor ? 0.3 : 0.1))
                        .frame(width: isMajor ? 2 : 1, height: isMajor ? 18 : isMinorMajor ? 12 : 6)
                        .offset(y: -146)
                        .rotationEffect(.degrees(Double(i) * 5))
                }

                ForEach(cardinalMarks, id: \.label) { mark in
                    VStack(spacing: 2) {
                        Text(mark.label)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(mark.label == "N" ? emerald : .white.opacity(0.45))
                    }
                    .offset(y: -120)
                    .rotationEffect(.degrees(mark.angle))
                    .rotationEffect(.degrees(qiblaService.heading))
                }

                ForEach(interCardinalMarks, id: \.label) { mark in
                    Text(mark.label)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .offset(y: -120)
                        .rotationEffect(.degrees(mark.angle))
                        .rotationEffect(.degrees(qiblaService.heading))
                }
            }
            .rotationEffect(.degrees(-qiblaService.heading))
            .animation(.interpolatingSpring(stiffness: 60, damping: 12), value: qiblaService.heading)

            VStack(spacing: 0) {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isAligned ? emerald : emerald.opacity(0.7))
                    .shadow(color: isAligned ? emerald.opacity(0.8) : emerald.opacity(0.3), radius: isAligned ? 12 : 4)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [isAligned ? emerald : emerald.opacity(0.6), emerald.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 80)
            }
            .offset(y: -50)
            .rotationEffect(.degrees(qiblaService.qiblaDirection))
            .animation(.interpolatingSpring(stiffness: 80, damping: 14), value: qiblaService.qiblaDirection)

            ZStack {
                Circle()
                    .fill(Color(red: 0.04, green: 0.06, blue: 0.12))
                    .frame(width: 64, height: 64)

                if isAligned {
                    Circle()
                        .fill(emerald.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .shadow(color: emerald.opacity(0.4), radius: 20)
                }

                Circle()
                    .stroke(
                        isAligned ? emerald.opacity(0.6) : Color.white.opacity(0.12),
                        lineWidth: 2
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "kaaba.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isAligned ? emerald : .white.opacity(0.5))
                    .shadow(color: isAligned ? emerald.opacity(0.6) : .clear, radius: 8)
            }
        }
        .frame(width: 300, height: 300)
    }

    @ViewBuilder
    private var alignmentIndicator: some View {
        if isAligned {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(emerald)
                    .shadow(color: emerald.opacity(0.5), radius: 6)
                Text("Kıble yönündesiniz")
                    .font(.subheadline.bold())
                    .foregroundStyle(emerald)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(emerald.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(emerald.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: emerald.opacity(0.2), radius: 16)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var kaabaCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [emerald.opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 72, height: 72)

                Image("QiblaKaaba")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(emerald.opacity(0.4), lineWidth: 1.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Kabe-i Muazzama")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Mekke, Suudi Arabistan")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
                if qiblaService.distanceToKaabaKM > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text("\(Int(qiblaService.distanceToKaabaKM)) km uzaklıkta")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(emerald.opacity(0.9))
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var isAligned: Bool {
        let normalized = ((qiblaService.qiblaDirection.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        return normalized < 5 || normalized > 355
    }

    private func bearingToCardinal(_ bearing: Double) -> String {
        let directions = ["Kuzey", "KD", "Doğu", "GD", "Güney", "GB", "Batı", "KB"]
        let index = Int(((bearing + 22.5).truncatingRemainder(dividingBy: 360)) / 45)
        return directions[max(0, min(index, 7))]
    }

    private var cardinalMarks: [CardinalMark] {
        [
            CardinalMark(label: "N", angle: 0),
            CardinalMark(label: "E", angle: 90),
            CardinalMark(label: "S", angle: 180),
            CardinalMark(label: "W", angle: 270)
        ]
    }

    private var interCardinalMarks: [CardinalMark] {
        [
            CardinalMark(label: "NE", angle: 45),
            CardinalMark(label: "SE", angle: 135),
            CardinalMark(label: "SW", angle: 225),
            CardinalMark(label: "NW", angle: 315)
        ]
    }
}

private struct CardinalMark {
    let label: String
    let angle: Double
}
