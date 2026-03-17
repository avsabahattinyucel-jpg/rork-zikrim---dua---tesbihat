import SwiftUI

struct DiyanetKnowledgeDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    let record: DiyanetKnowledgeRecord

    @State private var showFullSourceURL: Bool = false

    private var theme: AppTheme {
        themeManager.palette(using: systemColorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                metadataCard

                if let question = record.questionClean, !question.isEmpty, question != record.displayTitle {
                    questionCard(question)
                }

                officialTextCard
                sourceCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .themedScreenBackground()
        .themedNavigation(title: record.type.displayName, displayMode: .large)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.82), Color.teal.opacity(0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: record.type.systemImage)
                        .font(.title3)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.type.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(theme.accent)
                        .tracking(0.8)
                    Text(record.displayTitle)
                        .font(.title3.bold())
                        .foregroundStyle(theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .appCardStyle(theme, elevated: true, cornerRadius: 22)
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kayıt Bilgileri")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            infoRow(label: "Kaynak", value: record.sourceName)
            infoRow(label: "Alan adı", value: record.sourceHostLabel)

            if !record.categoryPath.isEmpty {
                infoRow(label: "Kategori", value: record.categoryPath.joined(separator: " > "))
            }

            if let year = record.decisionYear, !year.isEmpty {
                infoRow(label: "Yıl", value: year)
            }

            if let number = record.decisionNo, !number.isEmpty {
                infoRow(label: "Karar / No", value: number)
            }

            if let subject = record.subject, !subject.isEmpty, subject != record.displayTitle {
                infoRow(label: "Konu", value: subject)
            }
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }

    private func questionCard(_ question: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resmi Soru")
                .font(.caption.bold())
                .foregroundStyle(theme.secondaryText)
                .tracking(0.8)
            Text(question)
                .font(.body)
                .foregroundStyle(theme.primaryText)
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }

    private var officialTextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Resmi Metin", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            Text(record.officialBodyText)
                .font(.body)
                .foregroundStyle(theme.primaryText)
                .lineSpacing(5)
                .textSelection(.enabled)
        }
        .padding(16)
        .appCardStyle(theme, elevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(theme.accent.opacity(0.18), lineWidth: 1)
        )
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kaynak Bağlantısı")
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            Text(showFullSourceURL ? record.sourceURL : record.sourceHostLabel)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
                .textSelection(.enabled)

            HStack(spacing: 10) {
                Button {
                    showFullSourceURL.toggle()
                } label: {
                    Label(showFullSourceURL ? "Kısa göster" : "Tam URL göster", systemImage: "text.justify")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)

                if let url = URL(string: record.sourceURL) {
                    Link(destination: url) {
                        Label("Resmi kaynağı aç", systemImage: "link")
                            .font(.caption.bold())
                    }
                }
            }
            .foregroundStyle(theme.accent)
        }
        .padding(16)
        .appCardStyle(theme, elevated: false)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(theme.secondaryText)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(theme.primaryText)
            Spacer(minLength: 0)
        }
    }
}
