import Foundation
import CoreLocation

@MainActor
@Observable
final class PrayerTimesFeatureViewModel {
    private(set) var state: PrayerTimesLoadState = .idle
    private(set) var snapshot: PrayerTimesSnapshot?
    private(set) var tomorrowSnapshot: PrayerTimesSnapshot?

    private let service: PrayerTimesServiceProtocol

    init(service: PrayerTimesServiceProtocol? = nil) {
        self.service = service ?? PrayerTimesService.live()
    }

    func loadToday(request: PrayerTimesRequest) async {
        state = .loading

        let response = await service.fetch(request: request)
        snapshot = response.snapshot
        state = response.loadState

        let tomorrowDate = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: request.date) ?? request.date
        let tomorrowRequest = PrayerTimesRequest(
            date: tomorrowDate,
            context: request.context,
            calculationMethodID: request.calculationMethodID,
            methodLabel: request.methodLabel,
            madhabSchool: request.madhabSchool
        )
        let tomorrow = await service.fetch(request: tomorrowRequest)
        tomorrowSnapshot = tomorrow.snapshot
    }

    func refreshInBackground(request: PrayerTimesRequest) {
        Task {
            let response = await service.fetch(request: request)
            snapshot = response.snapshot
            state = response.loadState
        }
    }

    func nextPrayer(now: Date = Date()) -> PrayerTimeItem? {
        guard let snapshot else { return nil }
        return service.nextPrayer(from: snapshot, tomorrow: tomorrowSnapshot, now: now)
    }

    var sourceBadgeText: String? {
        guard let snapshot else { return nil }
        switch state {
        case .fallback:
            return PrayerTimesLocalizedStrings.sourceLabel(for: .fallback)
        case .stale:
            return PrayerTimesLocalizedStrings.sourceLabel(for: .cache)
        default:
            return PrayerTimesLocalizedStrings.sourceLabel(for: snapshot.sourceType)
        }
    }

    var updatedLabel: String {
        PrayerTimesLocalizedStrings.updatedNow()
    }
}
