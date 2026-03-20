import Foundation
import Testing
@testable import ZikrimDuaVeTesbihat

@MainActor
struct QuranVerseNotesRepositoryTests {

    @Test func savingAndLoadingVerseNotePersistsTrimmedContent() async throws {
        let suiteName = "QuranVerseNotesRepositoryTests.save.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let repository = ZikrimQuranVerseNotesRepository(defaults: defaults)
        let verse = QuranVerse(
            surahId: 36,
            verseNumber: 58,
            arabicText: "سَلَامٌ قَوْلًا مِن رَّبٍّ رَّحِيمٍ",
            turkishTranslation: "Merhametli Rab'den bir selam."
        )

        repository.save(
            noteText: "  Bu ayet cennet tasvirinde icime sukunet veriyor.  ",
            for: verse,
            surahName: "Yasin"
        )

        let note = try #require(repository.note(for: verse))
        #expect(note.noteText == "Bu ayet cennet tasvirinde icime sukunet veriyor.")
        #expect(note.surahName == "Yasin")
        #expect(note.id == "36:58")
    }

    @Test func deletingVerseNoteRemovesPersistedEntry() async throws {
        let suiteName = "QuranVerseNotesRepositoryTests.delete.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let repository = ZikrimQuranVerseNotesRepository(defaults: defaults)
        let verse = QuranVerse(
            surahId: 18,
            verseNumber: 10,
            arabicText: "رَبَّنَا آتِنَا مِن لَّدُنكَ رَحْمَةً",
            turkishTranslation: "Rabbimiz, bize katindan rahmet ver."
        )

        repository.save(noteText: "Genclik ve teslimiyet", for: verse, surahName: "Kehf")
        repository.deleteNote(for: verse)

        #expect(repository.note(for: verse) == nil)
    }
}
