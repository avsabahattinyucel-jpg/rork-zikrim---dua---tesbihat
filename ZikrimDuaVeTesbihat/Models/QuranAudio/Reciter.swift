import Foundation

nonisolated struct ReciterProviderConfiguration: Codable, Hashable, Sendable {
    let remoteIdentifier: String
    let basePath: String?

    init(remoteIdentifier: String, basePath: String? = nil) {
        self.remoteIdentifier = remoteIdentifier
        self.basePath = basePath
    }
}

nonisolated struct Reciter: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let displayNameKey: String
    let displayNameFallback: String
    let providerKind: AudioProviderKind
    let remoteIdentifier: String
    let basePath: String?
    let isPremiumLocked: Bool
    let providerConfigurations: [AudioProviderKind: ReciterProviderConfiguration]

    init(
        id: String,
        displayNameKey: String,
        displayNameFallback: String,
        providerKind: AudioProviderKind,
        remoteIdentifier: String,
        basePath: String? = nil,
        isPremiumLocked: Bool = false,
        providerConfigurations: [AudioProviderKind: ReciterProviderConfiguration]
    ) {
        self.id = id
        self.displayNameKey = displayNameKey
        self.displayNameFallback = displayNameFallback
        self.providerKind = providerKind
        self.remoteIdentifier = remoteIdentifier
        self.basePath = basePath
        self.isPremiumLocked = isPremiumLocked
        self.providerConfigurations = providerConfigurations
    }

    var localizedDisplayName: String {
        L10n.string(L10n.Key(displayNameKey, fallback: displayNameFallback))
    }

    func configuration(for provider: AudioProviderKind) -> ReciterProviderConfiguration? {
        providerConfigurations[provider]
    }
}

nonisolated enum ReciterRegistry {
    static let all: [Reciter] = [
        Reciter(
            id: "alafasy",
            displayNameKey: "quran_audio.reciter.alafasy",
            displayNameFallback: "Mishary Alafasy",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_alafasy",
            providerConfigurations: [
                .bundledAyahJSON: ReciterProviderConfiguration(remoteIdentifier: "quran_audio_recitation_alafasy"),
                .quranCom: ReciterProviderConfiguration(remoteIdentifier: "7"),
                .everyAyah: ReciterProviderConfiguration(
                    remoteIdentifier: "Alafasy_128kbps",
                    basePath: "Alafasy_128kbps"
                )
            ]
        ),
        Reciter(
            id: "abdul_basit",
            displayNameKey: "quran_audio.reciter.abdul_basit",
            displayNameFallback: "Abdul Basit",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_abdul_basit",
            isPremiumLocked: true,
            providerConfigurations: [
                .bundledAyahJSON: ReciterProviderConfiguration(remoteIdentifier: "quran_audio_recitation_abdul_basit"),
                .quranCom: ReciterProviderConfiguration(remoteIdentifier: "2"),
                .everyAyah: ReciterProviderConfiguration(
                    remoteIdentifier: "Abdul_Basit_Murattal_192kbps",
                    basePath: "Abdul_Basit_Murattal_192kbps"
                )
            ]
        ),
        Reciter(
            id: "muaiqly",
            displayNameKey: "quran_audio.reciter.muaiqly",
            displayNameFallback: "Maher Al-Muaiqly",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_muaiqly",
            isPremiumLocked: true,
            providerConfigurations: [
                .bundledAyahJSON: ReciterProviderConfiguration(remoteIdentifier: "quran_audio_recitation_muaiqly"),
                .everyAyah: ReciterProviderConfiguration(
                    remoteIdentifier: "MaherAlMuaiqly128kbps",
                    basePath: "MaherAlMuaiqly128kbps"
                )
            ]
        ),
        Reciter(
            id: "sudais",
            displayNameKey: "quran_audio.reciter.sudais",
            displayNameFallback: "Abdul Rahman Al-Sudais",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_sudais",
            isPremiumLocked: true,
            providerConfigurations: [
                .bundledAyahJSON: ReciterProviderConfiguration(remoteIdentifier: "quran_audio_recitation_sudais")
            ]
        ),
        Reciter(
            id: "minshawi",
            displayNameKey: "quran_audio.reciter.minshawi",
            displayNameFallback: "Muhammad Siddiq Al-Minshawi",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_minshawi",
            isPremiumLocked: true,
            providerConfigurations: [
                .bundledAyahJSON: ReciterProviderConfiguration(remoteIdentifier: "quran_audio_recitation_minshawi")
            ]
        )
    ]

    static var defaultReciter: Reciter {
        all.first ?? Reciter(
            id: "alafasy",
            displayNameKey: "quran_audio.reciter.alafasy",
            displayNameFallback: "Mishary Alafasy",
            providerKind: .bundledAyahJSON,
            remoteIdentifier: "quran_audio_recitation_alafasy",
            providerConfigurations: [:]
        )
    }

    static func reciter(withID id: String) -> Reciter? {
        all.first(where: { $0.id == id })
    }
}
