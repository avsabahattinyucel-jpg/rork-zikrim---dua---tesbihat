import SwiftUI

struct WatchContentView: View {
    @State private var store = WatchSessionStore()

    var body: some View {
        NavigationStack {
            ZStack {
                WatchSacredBackground()

                ScrollView {
                    VStack(spacing: 12) {
                        overviewCard

                        if !store.payload.counters.isEmpty {
                            counterPickerCard
                        }

                        if let counter = store.payload.selectedCounter {
                            counterHero(counter)
                            statsCard
                            actionRow
                        } else {
                            emptyState
                        }

                        statusCard
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Tesbih")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GUNLUK RITIM")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(Color.white.opacity(0.68))

                    Text(store.payload.selectedCounter?.title ?? "Zikirmatik")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)

                streakBadge
            }

            if let subtitle = clean(store.payload.selectedCounter?.subtitle) {
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(WatchGlassCard())
    }

    private var counterPickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AKTIF SAYAC")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(Color.white.opacity(0.64))

            Picker(
                "Sayac",
                selection: Binding(
                    get: { store.payload.selectedCounter?.id ?? "" },
                    set: { newValue in
                        guard !newValue.isEmpty else { return }
                        store.selectCounter(id: newValue)
                    }
                )
            ) {
                ForEach(store.payload.counters) { counter in
                    Text(counter.title).tag(counter.id)
                }
            }
            .pickerStyle(.navigationLink)
            .labelsHidden()
        }
        .padding(12)
        .background(WatchGlassCard(opacity: 0.80))
    }

    private func counterHero(_ counter: WatchCounterSnapshot) -> some View {
        VStack(spacing: 12) {
            if let stepProgress = clean(counter.stepProgressText) {
                Text(stepProgress.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color.white.opacity(0.64))
            }

            VStack(spacing: 8) {
                if let arabicText = clean(counter.arabicText) {
                    Text(arabicText)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .environment(\.layoutDirection, .rightToLeft)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(clean(counter.stepName) ?? counter.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let meaning = clean(counter.meaning) {
                    Text(meaning)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                store.increment()
            } label: {
                WatchCounterOrb(counter: counter)
            }
            .buttonStyle(.plain)

            if let transliteration = clean(counter.transliteration),
               transliteration.caseInsensitiveCompare(counter.title) != .orderedSame {
                Text(transliteration)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.68))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(WatchGlassCard(opacity: 0.88))
    }

    private var statsCard: some View {
        HStack(spacing: 8) {
            statPill(title: "Bugun", value: "\(store.payload.dailyCount)", tint: Color(red: 0.94, green: 0.73, blue: 0.29))
            statPill(title: "Hedef", value: "\(max(store.payload.dailyGoal, 0))", tint: Color(red: 0.48, green: 0.86, blue: 0.74))
            statPill(title: "Seri", value: "\(store.payload.streak)", tint: Color(red: 0.95, green: 0.52, blue: 0.34))
        }
        .padding(10)
        .background(WatchGlassCard(opacity: 0.76))
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            actionButton("Geri", systemImage: "arrow.uturn.backward", tint: Color(red: 0.30, green: 0.72, blue: 0.78)) {
                store.undo()
            }

            actionButton("Sifirla", systemImage: "arrow.counterclockwise", tint: Color(red: 0.84, green: 0.39, blue: 0.30)) {
                store.reset()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: 112, height: 112)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.48, green: 0.86, blue: 0.74).opacity(0.36),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 66
                        )
                    )
                    .frame(width: 92, height: 92)

                Image(systemName: "circle.hexagongrid.circle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.36))
            }

            VStack(spacing: 6) {
                Text("Saatte devam etmek icin bir tesbih sec")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                Text("iPhone uygulamasinda bir sayaç sec veya yeni bir tesbih olustur.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(14)
        .background(WatchGlassCard(opacity: 0.82))
    }

    private var statusCard: some View {
        VStack(spacing: 8) {
            if store.isSyncing {
                ProgressView()
                    .controlSize(.small)
                    .tint(Color(red: 0.92, green: 0.78, blue: 0.36))
            }

            Text(store.connectionStatus)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(WatchGlassCard(opacity: 0.68))
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .bold))
            Text("\(store.payload.streak)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(Color(red: 0.95, green: 0.77, blue: 0.36))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func statPill(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(tint.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(tint.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func clean(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct WatchCounterOrb: View {
    let counter: WatchCounterSnapshot

    private var progress: Double {
        min(max(counter.overallProgress, 0), 1)
    }

    private var displayedProgress: Double {
        progress > 0 ? max(progress, 0.02) : 0
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.49, green: 0.87, blue: 0.76).opacity(0.26),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 14,
                        endRadius: 84
                    )
                )
                .frame(width: 152, height: 152)
                .blur(radius: 12)

            Circle()
                .stroke(Color.white.opacity(0.13), lineWidth: 12)
                .frame(width: 132, height: 132)

            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.96, green: 0.78, blue: 0.35),
                            Color(red: 0.50, green: 0.86, blue: 0.74),
                            Color(red: 0.30, green: 0.72, blue: 0.78),
                            Color(red: 0.96, green: 0.78, blue: 0.35)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 132, height: 132)
                .shadow(color: Color(red: 0.50, green: 0.86, blue: 0.74).opacity(0.34), radius: 8, y: 4)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.20, blue: 0.19),
                            Color(red: 0.06, green: 0.10, blue: 0.11)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 88, height: 88)
                .blur(radius: 2)
                .offset(y: -10)

            VStack(spacing: 5) {
                Text("\(counter.currentCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text("/ \(counter.targetCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
        }
        .frame(width: 152, height: 152)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Sayac \(counter.currentCount) / \(counter.targetCount)")
        .accessibilityHint("Artirmak icin dokun")
    }
}

private struct WatchSacredBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.09, blue: 0.10),
                    Color(red: 0.07, green: 0.14, blue: 0.16),
                    Color(red: 0.02, green: 0.05, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.46, green: 0.83, blue: 0.75).opacity(0.22),
                    Color.clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 180
            )

            RadialGradient(
                colors: [
                    Color(red: 0.94, green: 0.76, blue: 0.31).opacity(0.16),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 12,
                endRadius: 180
            )

            WatchGeometryOverlay()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(18)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.clear,
                    Color.black.opacity(0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct WatchGlassCard: View {
    var opacity: Double = 0.86

    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(opacity * 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(opacity * 0.12), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(opacity * 0.06),
                                Color.clear,
                                Color.black.opacity(opacity * 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

private struct WatchGeometryOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) * 0.47
        let innerRadius = outerRadius * 0.72

        path.addEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))

        path.addEllipse(in: CGRect(
            x: center.x - innerRadius,
            y: center.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))

        for index in 0..<8 {
            let angle = Double(index) * (.pi / 4)
            let endPoint = CGPoint(
                x: center.x + cos(angle) * outerRadius,
                y: center.y + sin(angle) * outerRadius
            )
            path.move(to: center)
            path.addLine(to: endPoint)
        }

        return path
    }
}

#Preview {
    WatchContentView()
}
