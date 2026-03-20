import Foundation
import Testing
@testable import ZikrimDuaVeTesbihat

struct PrayerExperienceViewModelTests {

    @Test func beforeFajrTreatsIshaAsCurrentAndFajrAsNext() async throws {
        let timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let today = makePrayerTimes(for: "2026-03-20", timeZone: timeZone)
        let tomorrow = makePrayerTimes(for: "2026-03-21", timeZone: timeZone)
        let now = makeDate(day: "2026-03-20", time: "03:10", timeZone: timeZone)

        let current = PrayerViewModel.activePrayerName(prayerTimes: today, now: now)
        #expect(current == .isha)

        let liveViewModel = PrayerTimesViewModel()
        liveViewModel.prayerTimes = today
        liveViewModel.tomorrowPrayerTimes = tomorrow

        let prayerViewModel = PrayerViewModel(
            liveViewModel: liveViewModel,
            settings: PrayerSettings(),
            now: now,
            selectedPrayer: nil,
            locale: Locale(identifier: "tr_TR")
        )

        #expect(prayerViewModel?.currentPrayer.id == .isha)
        #expect(prayerViewModel?.nextTransitionPrayer.id == .fajr)
    }

    @Test func asrSelectionMarksEarlierPrayersAsPastAndLaterPrayersUpcoming() async throws {
        let timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let today = makePrayerTimes(for: "2026-03-20", timeZone: timeZone)
        let tomorrow = makePrayerTimes(for: "2026-03-21", timeZone: timeZone)
        let now = makeDate(day: "2026-03-20", time: "17:00", timeZone: timeZone)

        let liveViewModel = PrayerTimesViewModel()
        liveViewModel.prayerTimes = today
        liveViewModel.tomorrowPrayerTimes = tomorrow

        let prayerViewModel = try #require(
            PrayerViewModel(
                liveViewModel: liveViewModel,
                settings: PrayerSettings(),
                now: now,
                selectedPrayer: .asr,
                locale: Locale(identifier: "tr_TR")
            )
        )

        #expect(prayerViewModel.currentPrayer.id == .asr)
        #expect(prayerViewModel.nextTransitionPrayer.id == .maghrib)
        #expect(prayerViewModel.items.first(where: { $0.id == .fajr })?.state == .past)
        #expect(prayerViewModel.items.first(where: { $0.id == .dhuhr })?.state == .past)
        #expect(prayerViewModel.items.first(where: { $0.id == .maghrib })?.state == .upcoming)
    }

    @Test func obligatoryPrayerHelpersExcludeSunriseFromTracking() async throws {
        #expect(PrayerName.obligatoryCases == [.fajr, .dhuhr, .asr, .maghrib, .isha])
        #expect(PrayerName.sunrise.isObligatory == false)
        #expect(PrayerName.fajr.isObligatory == true)
    }

    @Test func qadaTrackerDefaultsStartAtZeroForObligatoryPrayers() async throws {
        let trackers = QadaTracker.defaultTrackers()

        #expect(trackers.count == 5)
        #expect(trackers[.sunrise] == nil)
        #expect(trackers[.fajr]?.outstandingCount == 0)
        #expect(trackers[.isha]?.completedQadaCount == 0)
    }

    @Test func qadaCalculationPreviewReflectsOutstandingTotalAcrossFivePrayers() async throws {
        let preview = StorageService.previewQadaCalculation(
            yearsNotPrayed: 2,
            existingTrackers: QadaTracker.defaultTrackers()
        )

        #expect(preview.yearsNotPrayed == 2)
        #expect(preview.estimatedCountPerPrayer == 730)
        #expect(preview.totalOutstanding == 3650)
        #expect(preview.isReset == false)
    }

    @Test func qadaTrackerProjectionPreservesCompletedCountWhenResettingCalculation() async throws {
        let existingTrackers: [PrayerName: QadaTracker] = [
            .fajr: QadaTracker(prayerType: .fajr, missedCount: 730, completedQadaCount: 12, userAdjustedValue: 718),
            .dhuhr: QadaTracker(prayerType: .dhuhr, missedCount: 730, completedQadaCount: 3, userAdjustedValue: 727)
        ]

        let updatedTrackers = StorageService.qadaTrackers(applying: nil, to: existingTrackers)

        #expect(updatedTrackers[.fajr]?.completedQadaCount == 12)
        #expect(updatedTrackers[.fajr]?.outstandingCount == 0)
        #expect(updatedTrackers[.dhuhr]?.completedQadaCount == 3)
        #expect(updatedTrackers[.dhuhr]?.outstandingCount == 0)
        #expect(updatedTrackers[.asr]?.completedQadaCount == 0)
    }

    @Test func spiritualContentProviderReturnsStableDailyItem() async throws {
        let date = makeDate(day: "2026-03-20", time: "21:00", timeZone: TimeZone(identifier: "Europe/Istanbul")!)

        let first = try #require(
            SpiritualContentProvider.dailyItem(for: .isha, date: date, languageCode: "tr")
        )
        let second = try #require(
            SpiritualContentProvider.dailyItem(for: .isha, date: date, languageCode: "tr")
        )

        #expect(first.id == second.id)
        #expect(first.prayer == .isha)
    }

    @Test func spiritualContentProviderFallsBackToEnglishWhenLanguageIsUnavailable() async throws {
        let date = makeDate(day: "2026-03-20", time: "12:30", timeZone: TimeZone(identifier: "Europe/Istanbul")!)

        let item = try #require(
            SpiritualContentProvider.dailyItem(for: .dhuhr, date: date, languageCode: "de")
        )

        #expect(item.languageCode == "en")
    }

    @Test func spiritualContentProviderCanAdvanceToNextItemWithinPrayerGroup() async throws {
        let date = makeDate(day: "2026-03-20", time: "05:45", timeZone: TimeZone(identifier: "Europe/Istanbul")!)

        let first = try #require(
            SpiritualContentProvider.dailyItem(for: .fajr, date: date, languageCode: "tr")
        )
        let next = try #require(
            SpiritualContentProvider.nextItem(after: first.id, for: .fajr, date: date, languageCode: "tr")
        )

        #expect(first.id != next.id)
        #expect(next.prayer == .fajr)
    }

    @Test func spiritualContentProviderKeepsIshaContentWithinNightTags() async throws {
        let date = makeDate(day: "2026-03-20", time: "21:10", timeZone: TimeZone(identifier: "Europe/Istanbul")!)

        let item = try #require(
            SpiritualContentProvider.dailyItem(for: .isha, date: date, languageCode: "tr")
        )

        #expect(item.tags.contains("isha") || item.tags.contains("yatsi"))
        #expect(item.tags.contains("huzur") || item.tags.contains("sukunet") || item.tags.contains("gece"))
    }

    @Test func prayerHistoryDayListsMissedPrayerNames() async throws {
        let day = PrayerHistoryDay(
            date: makeDate(day: "2026-03-20", time: "00:00", timeZone: TimeZone(identifier: "Europe/Istanbul")!),
            completionCount: 2,
            totalCount: 5,
            statuses: [
                .fajr: .prayed,
                .dhuhr: .missed,
                .asr: .unknown,
                .maghrib: .missed,
                .isha: .prayed
            ]
        )

        #expect(day.hasMissedPrayers == true)
        #expect(day.missedPrayerNames == ["Öğle", "Akşam"])
    }

    private func makePrayerTimes(for day: String, timeZone: TimeZone) -> PrayerTimes {
        PrayerTimes(
            fajr: makeDate(day: day, time: "05:32", timeZone: timeZone),
            sunrise: makeDate(day: day, time: "06:51", timeZone: timeZone),
            dhuhr: makeDate(day: day, time: "12:28", timeZone: timeZone),
            asr: makeDate(day: day, time: "16:42", timeZone: timeZone),
            maghrib: makeDate(day: day, time: "19:11", timeZone: timeZone),
            isha: makeDate(day: day, time: "20:37", timeZone: timeZone),
            date: makeDate(day: day, time: "00:00", timeZone: timeZone),
            timeZone: timeZone,
            locationName: "Istanbul",
            sourceName: "Diyanet"
        )
    }

    private func makeDate(day: String, time: String, timeZone: TimeZone) -> Date {
        let baseDate = Date.diyanetDateFormatter.date(from: day)!
        return baseDate.combined(time: time, timeZone: timeZone)!
    }
}

private extension Date {
    func combined(time: String, timeZone: TimeZone) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayStart = calendar.startOfDay(for: self)
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: dayStart)
    }
}
