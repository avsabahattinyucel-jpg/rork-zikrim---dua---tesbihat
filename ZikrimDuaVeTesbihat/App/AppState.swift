import Combine
import SwiftUI

enum AppTab: Int, CaseIterable, Hashable, Identifiable {
    case daily
    case dhikrs
    case guide
    case quran
    case more

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .daily: return L10n.string(.tabDaily)
        case .dhikrs: return L10n.string(.tabMyDhikr)
        case .guide: return L10n.string(.tabGuide)
        case .quran: return L10n.string(.tabQuran)
        case .more: return L10n.string(.tabMore)
        }
    }

    var systemImage: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .dhikrs: return "circle.circle.fill"
        case .guide: return "books.vertical.fill"
        case .quran: return "book.closed.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

enum AppDeepLink {
    case dashboard
    case more
    case dhikr
    case guide
    case quran
    case prayer
    case prayerTimes
    case legal(LegalDocumentType)

    init?(url: URL) {
        guard url.scheme?.lowercased() == "zikrim" else { return nil }

        switch (url.host ?? "").lowercased() {
        case "dashboard", "home":
            self = .dashboard
        case "more", "premium":
            self = .more
        case "dhikr":
            self = .dhikr
        case "guide":
            self = .guide
        case "quran":
            self = .quran
        case "prayer":
            self = .prayer
        case "prayer-times":
            self = .prayerTimes
        case "legal":
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
            switch path {
            case "privacy-policy":
                self = .legal(.privacyPolicy)
            case "terms-of-use":
                self = .legal(.termsOfUse)
            case "kvkk":
                self = .legal(.kvkk)
            default:
                return nil
            }
        default:
            return nil
        }
    }
}

enum DailyNavigationDestination: Hashable, Sendable {
    case prayer(PrayerName?)
}

struct DailyNavigationRequest: Identifiable, Equatable, Sendable {
    let id: UUID
    let destination: DailyNavigationDestination

    init(id: UUID = UUID(), destination: DailyNavigationDestination) {
        self.id = id
        self.destination = destination
    }
}

enum QuranNavigationDestination: Hashable, Sendable {
    case reader(QuranReadingRoute)
}

struct QuranNavigationRequest: Identifiable, Equatable, Sendable {
    let id: UUID
    let destination: QuranNavigationDestination

    init(id: UUID = UUID(), destination: QuranNavigationDestination) {
        self.id = id
        self.destination = destination
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .daily
    @Published var dailyNavigationRequest: DailyNavigationRequest?
    @Published var quranNavigationRequest: QuranNavigationRequest?
    @Published var presentedLegalDocument: LegalDocumentType?
    @Published var presentedNotificationDestination: AppNotificationDestination?

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func handleDeepLink(_ deepLink: AppDeepLink) {
        switch deepLink {
        case .dashboard:
            selectedTab = .daily
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
        case .more:
            selectedTab = .more
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedLegalDocument = nil
        case .dhikr:
            selectedTab = .dhikrs
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
        case .guide:
            selectedTab = .guide
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedLegalDocument = nil
        case .quran:
            selectedTab = .quran
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedLegalDocument = nil
        case .prayer, .prayerTimes:
            requestDailyNavigation(.prayer(nil))
            quranNavigationRequest = nil
            presentedLegalDocument = nil
        case .legal(let documentType):
            selectedTab = .more
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedLegalDocument = documentType
        }
    }

    func handleNotificationRoute(_ route: NotificationRoute) {
        presentedLegalDocument = nil

        switch route {
        case .prayerDetail(let prayer):
            requestDailyNavigation(.prayer(prayer))
            quranNavigationRequest = nil
            presentedNotificationDestination = nil
        case .dailyDua, .guideHome:
            selectedTab = .guide
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = nil
        case .dailyAyah:
            selectedTab = .quran
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = nil
        case .dhikrHome:
            selectedTab = .dhikrs
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = nil
        case .fridayContent:
            selectedTab = .daily
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = .fridayContent
        case .specialDay(let id, let title):
            selectedTab = .daily
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = .specialDay(id: id, title: title)
        case .notificationsSettings:
            selectedTab = .more
            dailyNavigationRequest = nil
            quranNavigationRequest = nil
            presentedNotificationDestination = .notificationSettings
        }
    }

    func requestDailyNavigation(_ destination: DailyNavigationDestination) {
        selectedTab = .daily
        dailyNavigationRequest = DailyNavigationRequest(destination: destination)
        quranNavigationRequest = nil
        presentedNotificationDestination = nil
    }

    func consumeDailyNavigationRequest(_ requestID: UUID) {
        guard dailyNavigationRequest?.id == requestID else { return }
        dailyNavigationRequest = nil
    }

    func requestQuranNavigation(_ destination: QuranNavigationDestination) {
        selectedTab = .quran
        quranNavigationRequest = QuranNavigationRequest(destination: destination)
        dailyNavigationRequest = nil
        presentedNotificationDestination = nil
    }

    func consumeQuranNavigationRequest(_ requestID: UUID) {
        guard quranNavigationRequest?.id == requestID else { return }
        quranNavigationRequest = nil
    }
}
