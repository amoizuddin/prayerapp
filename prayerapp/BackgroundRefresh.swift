import BackgroundTasks
import Foundation

/// Asks iOS to wake the app about every 3 days to refill prayer alerts from the saved
/// month of times. It only goes online when fewer than 13 days of times remain (about
/// every two and a half weeks). iOS treats the timing as "no earlier than" and may run later or skip
/// (Low Power Mode, Background App Refresh off, app swiped away); 12 days of lined-up
/// alerts cover that.
enum BackgroundRefresh {
    static let identifier = "com.amoizuddin.prayerapp.refresh"
    static let interval: TimeInterval = 3 * 24 * 60 * 60

    /// Requests the next wake-up. Replaces any earlier request.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// What runs when iOS wakes the app.
    static func run() async {
        schedule()
        let store = PrayerTimesStore.shared
        let now = AppClock.now
        await store.refreshIfNeeded(now: now)
        await PrayerAlertScheduler.shared.reschedule(days: store.days, now: now)
    }
}
