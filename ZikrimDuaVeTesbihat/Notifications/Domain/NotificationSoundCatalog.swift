import Foundation
import UserNotifications

struct NotificationSoundCatalog {
    static let prayerSoundFileName = "ezan.wav"

    static func sound(for selection: NotificationSoundSelection, isPrayer: Bool) -> UNNotificationSound {
        if isPrayer {
            return namedSound(prayerSoundFileName)
        }

        guard let fileName = previewFileName(for: selection) else {
            return .default
        }
        return namedSound(fileName)
    }

    static func previewFileName(for selection: NotificationSoundSelection) -> String? {
        switch selection.preset.normalizedForCurrentCatalog {
        case .system:
            return nil
        case .nur:
            return "nur.caf"
        case .safa:
            return "safa.caf"
        case .merve:
            return "merve.caf"
        case .huzur:
            return "huzur.caf"
        case .adhan, .gentle, .custom:
            return "nur.caf"
        }
    }

    static func resourceURL(for fileName: String, bundle: Bundle = .main) -> URL? {
        let nsFileName = fileName as NSString
        let resource = nsFileName.deletingPathExtension
        let fileExtension = nsFileName.pathExtension.isEmpty ? nil : nsFileName.pathExtension

        if let url = bundle.url(forResource: resource, withExtension: fileExtension) {
            return url
        }

        if let url = bundle.url(forResource: resource, withExtension: fileExtension, subdirectory: "Resources") {
            return url
        }

        let directURL = bundle.bundleURL.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        let nestedURL = bundle.bundleURL
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: nestedURL.path) {
            return nestedURL
        }

        return nil
    }

    private static func namedSound(_ fileName: String) -> UNNotificationSound {
        guard resourceURL(for: fileName) != nil else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(fileName))
    }
}
