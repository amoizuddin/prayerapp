import Foundation

/// The user's alert preferences, saved on the device.
nonisolated enum AlertSettings {
    /// Prayers that get an alert (Sunrise does not).
    static let alertPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    /// Whether this prayer's alert is Time Sensitive (comes through Focus modes). On by default.
    static func isTimeSensitive(_ prayer: Prayer) -> Bool {
        UserDefaults.standard.object(forKey: key(prayer)) as? Bool ?? true
    }

    static func setTimeSensitive(_ prayer: Prayer, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: key(prayer))
    }

    private static func key(_ prayer: Prayer) -> String { "timeSensitive.\(prayer.rawValue)" }
}
