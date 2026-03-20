import SwiftUI

struct LegalDocumentView: View {
    let documentType: LegalDocumentType

    private var document: LegalDocument {
        LegalContent.document(for: documentType)
    }

    private var appLocale: Locale {
        Locale(identifier: RabiaAppLanguage.currentCode())
    }

    var body: some View {
        Group {
            if documentType == .termsOfUse {
                StandardEULAView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        documentHeader

                        ForEach(Array(document.sections.enumerated()), id: \.element.id) { index, section in
                            VStack(alignment: .leading, spacing: 18) {
                                LegalSectionView(section: section)

                                if index < document.sections.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .textSelection(.enabled)
            }
        }
    }

    private var documentHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: documentType.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    )

                Text(document.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    metadataPill(title: L10n.string(.lastUpdatedLabel), value: formattedDate(document.lastUpdated))

                    if let version = document.version {
                        metadataPill(title: L10n.string(.surum), value: version)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    metadataPill(title: L10n.string(.lastUpdatedLabel), value: formattedDate(document.lastUpdated))

                    if let version = document.version {
                        metadataPill(title: L10n.string(.surum), value: version)
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(appLocale)
        )
    }

    private func metadataPill(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)

            Text(value)
                .foregroundStyle(.primary)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

private struct StandardEULAView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(LegalLinks.standardEULATitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Bu uygulama icin kullanim sartlari Apple'in standart son kullanici lisans sozlesmesi uzerinden sunulur.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Link(destination: LegalLinks.termsOfUseURL) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square")
                        Text(LegalLinks.standardEULATitle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Text(LegalLinks.termsOfUseURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(LegalLinks.standardEULATitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalSectionView: View {
    let section: LegalSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.heading)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            ForEach(section.paragraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.callout)
                    .lineSpacing(4)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
