import Foundation
import Combine

@MainActor
final class QuranReaderPreferencesStore: ObservableObject {
    @Published private(set) var preferences: QuranReaderPreferences

    private let defaults: UserDefaults
    private let preferencesKey = "quran_reader_preferences"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(QuranReaderPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            self.preferences = .default
        }
    }

    func update(_ mutate: (inout QuranReaderPreferences) -> Void) {
        var copy = preferences
        mutate(&copy)
        preferences = copy
        persist()
    }

    func replace(with preferences: QuranReaderPreferences) {
        self.preferences = preferences
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
    }
}
