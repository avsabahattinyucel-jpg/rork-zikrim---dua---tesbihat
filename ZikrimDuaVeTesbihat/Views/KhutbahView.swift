import SwiftUI
import AVFoundation

struct KhutbahView: View {
    @State private var service = KhutbahService()
    @State private var tts = GroqTTSService()
    @State private var fontSize: CGFloat = 16
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if service.isLoading && service.content == nil {
                loadingView
            } else if let khutbah = service.content {
                mainContent(khutbah)
            } else if let err = service.errorMessage {
                errorView(err)
            } else {
                loadingView
            }
        }
        .navigationTitle("Haftanın Hutbesi")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shareKhutbahSummaryCard()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task { await service.fetch() }
        .sheet(isPresented: $showShareSheet) {
            KhutbahShareSheet(items: shareItems)
        }
        .onDisappear { tts.stop() }
    }

    // MARK: - Main Content

    private func mainContent(_ khutbah: KhutbahContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard(khutbah)

                if service.insight != nil || service.isSummarizing || service.summarizeError != nil {
                    aiInsightsCard
                }

                fontSizeBar

                fullTextCard(khutbah)

                actionRow(khutbah)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    // MARK: - Header Card

    private func headerCard(_ khutbah: KhutbahContent) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(khutbah.title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !khutbah.date.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(khutbah.date)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 5) {
                    Image(systemName: "building.columns")
                        .font(.caption2)
                    Text("Diyanet İşleri Başkanlığı")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.7), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "text.book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - AI Insights Card

    @ViewBuilder
    private var aiInsightsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.teal)
                Text("Rabia Analizi")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if service.isSummarizing {
                    ProgressView()
                        .scaleEffect(0.75)
                        .tint(.teal)
                } else {
                    Text("Rabia")
                        .font(.caption2.bold())
                        .foregroundStyle(.teal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.teal.opacity(0.12))
                        .clipShape(.capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            if service.isSummarizing && service.insight == nil {
                HStack(spacing: 10) {
                    ProgressView().tint(.teal)
                    Text("Hutbe analiz ediliyor…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if let error = service.summarizeError, service.insight == nil {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rabia analizi şu an kullanılamıyor")
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Button {
                            Task {
                                if let content = service.content {
                                    await service.summarize(text: content.content)
                                }
                            }
                        } label: {
                            Label("Tekrar Dene", systemImage: "arrow.clockwise")
                                .font(.caption.bold())
                                .foregroundStyle(.teal)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            } else if let insight = service.insight {
                VStack(alignment: .leading, spacing: 0) {

                    themeSection(insight.theme)

                    Divider().padding(.horizontal, 16)

                    practicalSection(insight.practicalPoints)

                    Divider().padding(.horizontal, 16)

                    weeklyTaskSection(insight.weeklyTask)
                }

                Text("Bu içerik Rabia tarafından hazırlanmıştır.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.teal.opacity(0.07), Color.blue.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.teal.opacity(0.3), lineWidth: 1)
        )
    }

    private func themeSection(_ theme: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.teal)
                    .frame(width: 4, height: 16)
                Text("ANA TEMA")
                    .font(.caption.bold())
                    .foregroundStyle(.teal)
                    .tracking(0.8)
            }
            Text(theme)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func practicalSection(_ points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue)
                    .frame(width: 4, height: 16)
                Text("3 PRATİK UYGULAMA")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                    .tracking(0.8)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(points.prefix(3).enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                        Text(point)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weeklyTaskSection(_ task: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("HAFTALIK ÖDEV")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .tracking(0.8)
                Text(task)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.06))
    }

    // MARK: - Font Size Bar

    private var fontSizeBar: some View {
        HStack(spacing: 12) {
            Text("Yazı Boyutu")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    withAnimation { fontSize = max(12, fontSize - 2) }
                } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 32)
                }

                Text("\(Int(fontSize))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                Button {
                    withAnimation { fontSize = min(26, fontSize + 2) }
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 32)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Full Text Card

    private func fullTextCard(_ khutbah: KhutbahContent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Hutbe Metni", systemImage: "doc.text")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }

            Divider()

            Text(khutbah.content)
                .font(.system(size: fontSize))
                .foregroundStyle(.primary)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Action Row

    private func actionRow(_ khutbah: KhutbahContent) -> some View {
        HStack(spacing: 12) {
            Button {
                tts.toggle(text: khutbah.content)
            } label: {
                HStack(spacing: 8) {
                    if tts.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.teal)
                    } else {
                        Image(systemName: tts.isPlaying ? "stop.circle.fill" : "speaker.wave.2.fill")
                            .font(.subheadline)
                    }
                    Text(tts.isLoading ? "Yükleniyor..." : tts.isPlaying ? "Durdur" : "Dinle")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(tts.isPlaying ? Color.red.opacity(0.1) : tts.isLoading ? Color.orange.opacity(0.1) : Color.teal.opacity(0.1))
                )
                .foregroundStyle(tts.isPlaying ? .red : tts.isLoading ? .orange : .teal)
            }
            .disabled(tts.isLoading)

            Button {
                shareKhutbahSummaryCard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline)
                    Text("Paylaş")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 80, height: 80)
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.teal)
            }
            VStack(spacing: 6) {
                Text("Hutbe Yükleniyor")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Diyanet'ten bu haftanın hutbesi getiriliyor...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundStyle(.red.opacity(0.7))
            }

            VStack(spacing: 10) {
                Text("Hutbe Yüklenemedi")
                    .font(.title3.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await service.fetch() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Tekrar Dene")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 220, height: 50)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.teal))
                    .foregroundStyle(.white)
                }

                Link(destination: URL(string: "https://www.diyanethaber.com.tr/hutbeler")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("Diyanet Sitesini Aç")
                            .fontWeight(.medium)
                    }
                    .frame(width: 220, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundStyle(.teal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    @MainActor
    private func shareKhutbahSummaryCard() {
        guard let khutbah = service.content else { return }

        let card = KhutbahShareCardView(
            title: khutbah.title,
            date: khutbah.date,
            insight: service.insight,
            fallbackText: khutbah.content
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0
        if let image = renderer.uiImage {
            shareItems = [image]
        } else {
            let fallbackText = "Cuma Hutbesi Özeti\n\n\(khutbah.title)\n\nZikrim - Dua & Tesbihat"
            shareItems = [fallbackText]
        }
        showShareSheet = true
    }
}

// MARK: - Share Sheet

struct KhutbahShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
