import SwiftUI

struct KhutbahShareCardView: View {
    let title: String
    let date: String
    let insight: KhutbahInsight?
    let fallbackText: String

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                topBranding

                Spacer().frame(height: 44)

                titleSection

                Spacer().frame(height: 36)

                if let insight {
                    insightCards(insight)
                } else {
                    fallbackContent
                }

                Spacer()

                bottomBranding

                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 48)

            decorativeElements
        }
        .frame(width: 1080, height: 1920)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.04, green: 0.08, blue: 0.18), location: 0),
                    .init(color: Color(red: 0.06, green: 0.16, blue: 0.28), location: 0.35),
                    .init(color: Color(red: 0.04, green: 0.22, blue: 0.32), location: 0.65),
                    .init(color: Color(red: 0.02, green: 0.10, blue: 0.20), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.teal.opacity(0.15), .clear],
                center: .init(x: 0.3, y: 0.25),
                startRadius: 50,
                endRadius: 500
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.10), .clear],
                center: .init(x: 0.8, y: 0.7),
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Decorative

    private var decorativeElements: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.03), lineWidth: 1.5)
                .frame(width: 600, height: 600)
                .offset(x: -200, y: -400)

            Circle()
                .stroke(Color.teal.opacity(0.05), lineWidth: 1)
                .frame(width: 400, height: 400)
                .offset(x: 300, y: 500)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.06), Color.cyan.opacity(0.03)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(x: 40, y: 100)
                }
            }

            VStack {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.12))
                        .offset(x: 80, y: 180)
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.08))
                        .offset(x: -60, y: 240)
                }
                Spacer()
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.10))
                        .offset(x: 120, y: -200)
                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Branding

    private var topBranding: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.teal.opacity(0.7))

                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 20)

                Text("CUMA HUTBESİ")
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .tracking(4)
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            if !date.isEmpty {
                Text(date)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.teal.opacity(0.8))
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 20) {
            capsuleDivider

            Text(title)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            capsuleDivider
        }
    }

    private var capsuleDivider: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.teal.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(Color.teal.opacity(0.6))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Insight Cards

    private func insightCards(_ insight: KhutbahInsight) -> some View {
        VStack(spacing: 20) {
            themeCard(insight.theme)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.yellow.opacity(0.9))
                    Text("3 ÖNEMLİ DERS")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(.bottom, 4)

                ForEach(Array(insight.practicalPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                    lessonCard(index: index + 1, text: point)
                }
            }

            if !insight.weeklyTask.isEmpty {
                weeklyTaskCard(insight.weeklyTask)
            }
        }
    }

    private func themeCard(_ theme: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.teal)
                    .frame(width: 4, height: 20)
                Text("ANA TEMA")
                    .font(.system(size: 15, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.teal)
            }

            Text(theme)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.teal.opacity(0.4), Color.teal.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func lessonCard(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.teal, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(text)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func weeklyTaskCard(_ task: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.9), Color.yellow.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("HAFTALIK GÖREV")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.orange.opacity(0.9))
                Text(task)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Fallback

    private var fallbackContent: some View {
        Text(String(fallbackText.prefix(500)))
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.85))
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
            )
    }

    // MARK: - Bottom Branding

    private var bottomBranding: some View {
        VStack(spacing: 14) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 1)

            HStack(spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.teal)

                Text("Zikrim")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)

                Text("Dua & Tesbihat")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Text("Manevi Yolculuğunda Yanında")
                .font(.system(size: 15, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.teal.opacity(0.6))
        }
    }
}
