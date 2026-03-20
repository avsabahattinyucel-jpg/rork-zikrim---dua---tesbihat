import Foundation

nonisolated func paddedSurah(_ surah: Int) -> String {
    String(format: "%03d", surah)
}

nonisolated func paddedAyah(_ ayah: Int) -> String {
    String(format: "%03d", ayah)
}

nonisolated func verseFileName(surah: Int, ayah: Int) -> String {
    "\(paddedSurah(surah))\(paddedAyah(ayah)).mp3"
}

nonisolated func ayahCount(forSurah surah: Int) -> Int {
    QuranSurahData.surahs.first(where: { $0.id == surah })?.totalVerses ?? 0
}

nonisolated func nextAyahNumber(after request: AyahAudioRequest) -> Int? {
    let totalAyahs = ayahCount(forSurah: request.surah)
    guard request.ayah < totalAyahs else { return nil }
    return request.ayah + 1
}
