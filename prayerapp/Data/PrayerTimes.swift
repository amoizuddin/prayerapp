import Foundation

/// The six daily times shown in the app, in order.
nonisolated enum Prayer: String, Codable, CaseIterable, Sendable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var name: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }
}

/// One prayer at a specific moment.
nonisolated struct PrayerTime: Codable, Hashable, Sendable {
    let prayer: Prayer
    let date: Date
}

/// All prayer times for one calendar day at the masjid's location.
nonisolated struct DayTimes: Codable, Hashable, Sendable {
    /// The day these times belong to, as "yyyy-MM-dd" in the location's time zone.
    let day: String
    let times: [PrayerTime]
}

/// Anything that can supply prayer times. Aladhan today; IF's iqamah times later.
protocol PrayerTimesSource: Sendable {
    /// Returns times for `count` consecutive days starting with the day containing `start`.
    func fetchDays(from start: Date, count: Int) async throws -> [DayTimes]
}

/// Where the masjid is. Day boundaries ("today") are judged in this time zone.
nonisolated enum MasjidLocation {
    static let latitude = 41.8800     // Lombard, IL
    static let longitude = -88.0078
    static let timeZone = TimeZone(identifier: "America/Chicago")!

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func dayKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
