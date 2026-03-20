import SwiftUI

struct QuranAudioPremiumUpsellSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let prompt: QuranAudioPremiumPrompt
    let authService: AuthService

    @State private var showPremiumPaywall: Bool = false

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(theme.accent.opacity(0.10))
                            .frame(width: 64, height: 64)

                        Image(systemName: "waveform.badge.plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }

                    Text(prompt.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(theme.textPrimary)

                    Text(prompt.message)
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.leading)

                    Text(L10n.string(.quranAudioPrayerSurahsFree))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }

                VStack(spacing: 10) {
                    Button {
                        showPremiumPaywall = true
                    } label: {
                        Text(L10n.string(.quranAudioUpgrade))
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .themedPrimaryButton(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)

                    Button(L10n.string(.quranAudioMaybeLater)) {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(theme.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .appScreenBackground(theme)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.tamam2) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumView(authService: authService)
        }
    }
}
