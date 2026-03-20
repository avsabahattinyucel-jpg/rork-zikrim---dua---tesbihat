import Foundation

enum NotificationRoute: Equatable, Sendable {
    case prayerDetail(PrayerName)
    case dailyDua
    case guideHome
    case dailyAyah
    case dhikrHome
    case fridayContent
    case specialDay(id: String, title: String?)
    case notificationsSettings

    private enum PayloadKey {
        static let route = "zikrim.notification.route"
        static let prayer = "zikrim.notification.prayer"
        static let specialDayID = "zikrim.notification.special_day_id"
        static let specialDayTitle = "zikrim.notification.special_day_title"
        static let deepLink = "zikrim.notification.url"
    }

    var deepLinkURL: URL {
        switch self {
        case .prayerDetail(let prayer):
            return URL(string: "zikrim://prayer?name=\(prayer.rawValue)")!
        case .dailyDua, .guideHome:
            return URL(string: "zikrim://guide")!
        case .dailyAyah:
            return URL(string: "zikrim://quran")!
        case .dhikrHome:
            return URL(string: "zikrim://dhikr")!
        case .fridayContent:
            return URL(string: "zikrim://guide/friday")!
        case .specialDay(let id, _):
            return URL(string: "zikrim://special-day/\(id)")!
        case .notificationsSettings:
            return URL(string: "zikrim://more/notifications")!
        }
    }

    var userInfo: [AnyHashable: Any] {
        var info: [AnyHashable: Any] = [
            PayloadKey.deepLink: deepLinkURL.absoluteString
        ]

        switch self {
        case .prayerDetail(let prayer):
            info[PayloadKey.route] = "prayer_detail"
            info[PayloadKey.prayer] = prayer.rawValue
        case .dailyDua:
            info[PayloadKey.route] = "daily_dua"
        case .guideHome:
            info[PayloadKey.route] = "guide_home"
        case .dailyAyah:
            info[PayloadKey.route] = "daily_ayah"
        case .dhikrHome:
            info[PayloadKey.route] = "dhikr_home"
        case .fridayContent:
            info[PayloadKey.route] = "friday_content"
        case .specialDay(let id, let title):
            info[PayloadKey.route] = "special_day"
            info[PayloadKey.specialDayID] = id
            if let title {
                info[PayloadKey.specialDayTitle] = title
            }
        case .notificationsSettings:
            info[PayloadKey.route] = "notification_settings"
        }

        return info
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard let rawRoute = userInfo[PayloadKey.route] as? String else {
            return nil
        }

        switch rawRoute {
        case "prayer_detail":
            guard let prayerRaw = userInfo[PayloadKey.prayer] as? String,
                  let prayer = PrayerName(rawValue: prayerRaw) else {
                return nil
            }
            self = .prayerDetail(prayer)
        case "daily_dua":
            self = .dailyDua
        case "guide_home":
            self = .guideHome
        case "daily_ayah":
            self = .dailyAyah
        case "dhikr_home":
            self = .dhikrHome
        case "friday_content":
            self = .fridayContent
        case "special_day":
            guard let id = userInfo[PayloadKey.specialDayID] as? String else {
                return nil
            }
            self = .specialDay(id: id, title: userInfo[PayloadKey.specialDayTitle] as? String)
        case "notification_settings":
            self = .notificationsSettings
        default:
            return nil
        }
    }
}

enum AppNotificationDestination: Identifiable, Equatable, Sendable {
    case dailyDua
    case fridayContent
    case specialDay(id: String, title: String?)
    case notificationSettings

    var id: String {
        switch self {
        case .dailyDua:
            return "dailyDua"
        case .fridayContent:
            return "fridayContent"
        case .specialDay(let id, _):
            return "specialDay_\(id)"
        case .notificationSettings:
            return "notificationSettings"
        }
    }
}
