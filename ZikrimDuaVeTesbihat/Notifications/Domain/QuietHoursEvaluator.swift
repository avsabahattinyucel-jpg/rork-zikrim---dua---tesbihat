import Foundation

struct QuietHoursEvaluator: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func isDateWithinQuietHours(_ date: Date, configuration: QuietHoursConfiguration) -> Bool {
        guard configuration.isEnabled else { return false }

        let minute = minutesSinceMidnight(for: date)
        let start = configuration.start.minutesSinceMidnight
        let end = configuration.end.minutesSinceMidnight

        if start == end {
            return true
        }

        if start < end {
            return minute >= start && minute < end
        }

        return minute >= start || minute < end
    }

    func shouldSuppressNonCriticalReminder(at date: Date, configuration: QuietHoursConfiguration) -> Bool {
        isDateWithinQuietHours(date, configuration: configuration)
    }

    private func minutesSinceMidnight(for date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
