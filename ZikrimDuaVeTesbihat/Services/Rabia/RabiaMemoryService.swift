import Foundation

@MainActor
final class RabiaMemoryService {
    static let shared = RabiaMemoryService()

    private let storageKey = "rabia_memory"

    private init() {}

    func loadMemory() -> RabiaMemory {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let memory = try? JSONDecoder().decode(RabiaMemory.self, from: data) else {
            return RabiaMemory()
        }
        return memory
    }

    func saveMemory(_ memory: RabiaMemory) {
        guard let data = try? JSONEncoder().encode(memory) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func updateName(_ name: String) {
        var memory = loadMemory()
        memory.name = name
        saveMemory(memory)
    }

    func updateCity(_ city: String) {
        var memory = loadMemory()
        memory.city = city
        saveMemory(memory)
    }

    func updateFavoriteDhikr(_ dhikr: String) {
        var memory = loadMemory()
        memory.favoriteDhikr = dhikr
        saveMemory(memory)
    }

    func updateMood(_ mood: String) {
        var memory = loadMemory()
        memory.lastMood = mood
        saveMemory(memory)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
