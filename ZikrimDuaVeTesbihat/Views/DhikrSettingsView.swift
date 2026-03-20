import SwiftUI

struct DhikrSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    let storage: StorageService

    var body: some View {
        let palette = themeManager.palette(using: systemColorScheme)

        ZStack {
            palette.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    settingsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(L10n.string(.dhikrSettingsTitle))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            DhikrSettingsToggleRow(
                title: .dhikrSettingsSound,
                icon: "speaker.wave.2",
                isOn: Binding(
                    get: { storage.profile.soundEnabled },
                    set: { newValue in
                        storage.profile.soundEnabled = newValue
                        storage.saveProfile()
                    }
                )
            )

            Divider().padding(.leading, 52)

            DhikrSettingsToggleRow(
                title: .dhikrSettingsVibration,
                icon: "iphone.radiowaves.left.and.right",
                isOn: Binding(
                    get: { storage.profile.vibrationEnabled },
                    set: { newValue in
                        storage.profile.vibrationEnabled = newValue
                        storage.saveProfile()
                    }
                )
            )
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
    }
}

private struct DhikrSettingsToggleRow: View {
    let title: L10n.Key
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
