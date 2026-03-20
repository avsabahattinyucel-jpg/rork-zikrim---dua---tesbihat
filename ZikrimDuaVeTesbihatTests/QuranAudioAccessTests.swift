import Foundation
import Testing
@testable import ZikrimDuaVeTesbihat

@MainActor
struct QuranAudioAccessTests {

    @Test func freeUsersCanQueueEntirePrayerSurah() async throws {
        let service = AyahAudioPlayerService(isPremiumUser: false)
        let queue = try #require(service.queueForTesting(surahID: 94, startingAt: 1))

        #expect(queue.count == 8)
        #expect(queue.first?.ayahNumber == 1)
        #expect(queue.last?.ayahNumber == 8)
    }

    @Test func freeUsersStillGetSingleAyahForPremiumSurahs() async throws {
        let service = AyahAudioPlayerService(isPremiumUser: false)
        let queue = try #require(service.queueForTesting(surahID: 2, startingAt: 5))

        #expect(queue.count == 1)
        #expect(queue.first?.ayahNumber == 5)
    }

    @Test func prayerSurahPolicyCoversShortPrayerSurahs() async throws {
        #expect(QuranAudioAccessPolicy.accessLevel(for: 1) == .free)
        #expect(QuranAudioAccessPolicy.accessLevel(for: 93) == .free)
        #expect(QuranAudioAccessPolicy.accessLevel(for: 97) == .free)
        #expect(QuranAudioAccessPolicy.accessLevel(for: 114) == .free)
        #expect(QuranAudioAccessPolicy.accessLevel(for: 92) == .premium)
    }

    @Test func ayahPlaybackUsesCachedLocalFile() async throws {
        let localURL = URL(fileURLWithPath: "/tmp/fatiha-1.mp3")
        let remoteURL = try #require(URL(string: "https://example.com/fatiha-1.mp3"))
        let request = AyahAudioRequest(
            surah: 1,
            ayah: 1,
            reciter: ReciterRegistry.defaultReciter
        )
        let track = AyahAudioTrack(
            request: request,
            providerKind: request.reciter.providerKind,
            remoteURL: remoteURL,
            localFileURL: localURL
        )

        #expect(track.playbackURL == localURL)
    }

    @Test func quranAudioLocalizationKeysExistInStringCatalog() async throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let audioKeysSourceURL = repositoryRoot.appendingPathComponent("ZikrimDuaVeTesbihat/Support/AudioL10nKeys.swift")
        let recitersSourceURL = repositoryRoot.appendingPathComponent("ZikrimDuaVeTesbihat/Models/QuranAudio/Reciter.swift")
        let stringCatalogURL = repositoryRoot.appendingPathComponent("Localizable.xcstrings")

        let audioKeysSource = try String(contentsOf: audioKeysSourceURL, encoding: .utf8)
        let recitersSource = try String(contentsOf: recitersSourceURL, encoding: .utf8)
        let stringCatalogData = try Data(contentsOf: stringCatalogURL)
        let stringCatalogObject = try JSONSerialization.jsonObject(with: stringCatalogData) as? [String: Any]
        let stringEntries = try #require(stringCatalogObject?["strings"] as? [String: Any])

        let definedKeys = Set(stringEntries.keys)
        let requiredKeys = Set(
            sourceMatches(in: audioKeysSource, pattern: #"L10n\.Key\("([^"]+)""#)
            + sourceMatches(in: recitersSource, pattern: #"displayNameKey: "([^"]+)""#)
        )
        let missingKeys = requiredKeys.subtracting(definedKeys).sorted()

        #expect(missingKeys.isEmpty, "Missing Quran audio localization keys: \(missingKeys.joined(separator: ", "))")
    }

    @Test func appDeclaresBackgroundAudioModeForQuranPlayback() async throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let infoPlistURL = repositoryRoot.appendingPathComponent("ZikrimDuaVeTesbihat/Info.plist")

        let plistData = try Data(contentsOf: infoPlistURL)
        let plistObject = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        let backgroundModes = try #require(plistObject?["UIBackgroundModes"] as? [String])

        #expect(backgroundModes.contains("audio"))
    }

    private func sourceMatches(in source: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(source.startIndex..., in: source)

        return regex.matches(in: source, range: nsRange).compactMap { match in
            guard let range = Range(match.range(at: 1), in: source) else { return nil }
            return String(source[range])
        }
    }
}
