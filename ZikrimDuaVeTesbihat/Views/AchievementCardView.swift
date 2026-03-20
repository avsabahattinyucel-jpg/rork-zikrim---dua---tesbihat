import SwiftUI

struct AchievementCardView: View {
    let date: Date
    let progress: Double
    let streak: Int
    let prayerCount: Int
    let habitCount: Int
    var reflectionNote: String? = nil

    private var templateIndex: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
    }

    private static let quotes: [(text: String, source: String)] = [
        ("Allah'ı zikredin, O da sizi zikretsin.", "Bakara 152"),
        ("Şüphesiz zorlukla birlikte kolaylık vardır.", "İnşirah 6"),
        ("Rabbim, kalbimi genişlet ve işimi kolaylaştır.", "Taha 25-26"),
        ("Kim Allah'a tevekkül ederse Allah ona yeter.", "Talak 3"),
        ("Sabredenler ecirleri hesapsız ödenecek olanlardır.", "Zümer 10"),
        ("Allah güzel ahlakı tamamlamak için gönderildi.", "Hadis"),
        ("Kişinin değeri, güzel ahlakıyla ölçülür.", "Hadis"),
        ("Amellerin en hayırlısı, az da olsa devamlı olanıdır.", "Hadis"),
        ("Her zorlukla birlikte bir kolaylık vardır.", "İnşirah 5"),
        ("Bizi doğru yola ilet.", "Fatiha 6")
    ]

    private var randomQuote: (text: String, source: String) {
        let index = Calendar.current.component(.day, from: date) % Self.quotes.count
        return Self.quotes[index]
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            cardBackground

            VStack(spacing: 0) {
                topDecorativeStrip

                VStack(spacing: 20) {
                    brandingRow
                    progressSection
                    statsRow
                    quoteSection
                    footerRow
                }
                .padding(24)
            }
        }
        .frame(width: 360, height: 500)
        .clipShape(.rect(cornerRadius: 24))
    }

    private var cardBackground: some View {
        let assets = ["share_bg_moon_soft", "share_bg_mosque_sunrise", "gunluk_bg_summary_moon"]
        let asset = assets[templateIndex % assets.count]

        return ZStack {
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(width: 360, height: 500)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.44),
                    Color.black.opacity(0.80)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var topDecorativeStrip: some View {
        LinearGradient(
            colors: [Color.teal, Color.cyan.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 4)
    }

    private var brandingRow: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 1.0, green: 211 / 255, blue: 107 / 255))
                Text(.islamiGunluk)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var progressSection: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 14)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [Color.teal, Color.cyan, Color.teal],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text(L10n.format(.numberFormat, Int64(Int(progress * 100))))
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(L10n.string(.percentSymbol))
                        .font(.caption)
                        .foregroundStyle(Color(red: 1.0, green: 211 / 255, blue: 107 / 255))
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                progressDetailRow(icon: "moon.fill", label: L10n.string(.namazLabel), value: "\(prayerCount)/5")
                progressDetailRow(icon: "checkmark.circle.fill", label: L10n.string(.aliskanlikLabel), value: "\(habitCount)/\(DailyHabitRecord.defaultHabits.count)")
                progressDetailRow(icon: "flame.fill", label: L10n.string(.widgetStreakTitle), value: L10n.format(.daysCountFormat, Int64(streak)))
            }
        }
        .padding(.vertical, 8)
    }

    private func progressDetailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color(red: 1.0, green: 211 / 255, blue: 107 / 255))
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            badgeCell(
                icon: prayerCount == 5 ? "checkmark.seal.fill" : "moon.stars.fill",
                label: prayerCount == 5
                    ? L10n.string(.tumNamazlar)
                    : L10n.format(.prayerCountFormat, Int64(prayerCount)),
                color: prayerCount == 5 ? .teal : .white.opacity(0.4)
            )
            badgeCell(
                icon: "flame.fill",
                label: L10n.format(.dailyStreakFormat, Int64(streak)),
                color: streak > 0 ? .orange : .white.opacity(0.4)
            )
            badgeCell(
                icon: "moon.stars.fill",
                label: progress >= 1.0
                    ? L10n.string(.tamPuan)
                    : L10n.format(.progressPercentFormat, Int64(Int(progress * 100))),
                color: progress >= 1.0 ? .yellow : .white.opacity(0.4)
            )
        }
    }

    private func badgeCell(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.07))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var quoteSection: some View {
        VStack(spacing: 8) {
            if let note = reflectionNote, !note.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.teal)
                    Text(.hikmetNotu)
                        .font(.caption2.bold())
                        .foregroundStyle(.teal)
                }
                Text(note)
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Text(.buIcerikRabiaTarafindanHazirlanmistir)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                Text("❝ \(randomQuote.text) ❞")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                if !randomQuote.source.isEmpty {
                    Text("— \(randomQuote.source)")
                        .font(.caption)
                        .foregroundStyle(.teal.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var footerRow: some View {
        HStack {
            Text(.zikrimIslamiGunluk)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < prayerCount ? Color.teal : Color.white.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
