import SwiftUI

struct LegalHubView: View {
    private let documentTypes: [LegalDocumentType] = [.kvkk, .privacyPolicy]

    var body: some View {
        List {
            Section {
                ForEach(documentTypes) { documentType in
                    NavigationLink {
                        LegalDocumentView(documentType: documentType)
                    } label: {
                        legalRow(for: documentType)
                    }
                }
            } footer: {
                Text(.legalDocumentsUpdateNote)
                    .font(.footnote)
            }

            Section("Resmi bağlantılar") {
                externalLinkRow(
                    title: "melsalegal.com",
                    subtitle: "Tanıtım ve genel bilgilendirme sayfası",
                    systemImage: "globe",
                    url: LegalLinks.marketingURL
                )

                externalLinkRow(
                    title: "KVKK Aydınlatma Metni",
                    subtitle: LegalLinks.kvkkURL.absoluteString,
                    systemImage: "hand.raised.square",
                    url: LegalLinks.kvkkURL
                )

                externalLinkRow(
                    title: L10n.string(.gizlilikPolitikasi),
                    subtitle: LegalLinks.privacyPolicyURL.absoluteString,
                    systemImage: "lock.shield",
                    url: LegalLinks.privacyPolicyURL
                )

                externalLinkRow(
                    title: LegalLinks.standardEULATitle,
                    subtitle: LegalLinks.termsOfUseURL.absoluteString,
                    systemImage: "doc.text",
                    url: LegalLinks.termsOfUseURL
                )

                externalLinkRow(
                    title: "Destek merkezi",
                    subtitle: LegalLinks.supportURL.absoluteString,
                    systemImage: "questionmark.circle",
                    url: LegalLinks.supportURL
                )

                if let supportEmailURL = LegalLinks.supportEmailURL {
                    externalLinkRow(
                        title: "Destek e-postası",
                        subtitle: LegalLinks.supportEmail,
                        systemImage: "envelope",
                        url: supportEmailURL
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string(.legalTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legalRow(for documentType: LegalDocumentType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: documentType.iconName)
                .frame(width: 24, alignment: .leading)
                .foregroundStyle(Color.accentColor)

            Text(documentType.titleKey)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func externalLinkRow(
        title: String,
        subtitle: String,
        systemImage: String,
        url: URL
    ) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 24, alignment: .leading)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
