import Foundation

/// The app's idea of "now". In Debug builds, launching with `-fakeNow 2026-11-07T17:57:50`
/// (local time) shifts the clock so prayer changes can be tested without waiting.
nonisolated enum AppClock {
    private static let offset: TimeInterval = {
        #if DEBUG
        if let text = UserDefaults.standard.string(forKey: "fakeNow") {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let fake = formatter.date(from: text) { return fake.timeIntervalSinceNow }
        }
        #endif
        return 0
    }()

    static var now: Date { Date().addingTimeInterval(offset) }
}
