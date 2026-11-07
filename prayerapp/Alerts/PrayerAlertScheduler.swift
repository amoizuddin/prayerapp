import Foundation
import UserNotifications

/// Lines up local alerts for the coming prayers. iOS keeps at most 64 pending alerts,
/// so we schedule 12 days (5 a day = 60) plus a "running low" reminder, and redo it
/// whenever the app opens, wakes in the background, the times refresh, or a setting changes.
final class PrayerAlertScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PrayerAlertScheduler()

    private let center = UNUserNotificationCenter.current()
    private let maxPrayerAlerts = 60

    /// Call once at launch so alerts also show while the app is open.
    func activate() {
        center.delegate = self
    }

    /// Shows iOS's permission prompt the first time; afterwards returns the saved answer.
    func requestPermission() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// The refill currently running, so refills take turns instead of overlapping
    /// (overlapping ones could each clear the list and then both add, leaving duplicates).
    private var lastRefill: Task<Void, Never>?

    func reschedule(days: [DayTimes], now: Date) async {
        let previous = lastRefill
        let refill = Task {
            await previous?.value
            await performReschedule(days: days, now: now)
        }
        lastRefill = refill
        await refill.value
    }

    private func performReschedule(days: [DayTimes], now: Date) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        center.removeAllPendingNotificationRequests()

        let upcoming = days.flatMap(\.times)
            .filter { AlertSettings.alertPrayers.contains($0.prayer) && $0.date > now }
            .sorted { $0.date < $1.date }
            .prefix(maxPrayerAlerts)

        for time in upcoming {
            let content = UNMutableNotificationContent()
            content.title = time.prayer.name
            content.body = "It's time for \(time.prayer.name) · \(time.date.formatted(date: .omitted, time: .shortened))"
            content.sound = .default
            content.interruptionLevel = AlertSettings.isTimeSensitive(time.prayer) ? .timeSensitive : .active
            await add(id: "prayer-\(Int(time.date.timeIntervalSince1970))-\(time.prayer.rawValue)", content: content, at: time.date, now: now)
        }

        // About a day before the lined-up alerts run out. Opening the app pushes this back.
        if let last = upcoming.last {
            let content = UNMutableNotificationContent()
            content.title = "Don't miss a prayer"
            content.body = "Open Prayer Times to keep getting alerts."
            content.sound = .default
            await add(id: "running-low", content: content, at: last.date.addingTimeInterval(-24 * 60 * 60), now: now)
        }

        #if DEBUG
        // Launch with `-testAlertIn 60` to get a sample Asr alert 60 seconds from now.
        let testDelay = UserDefaults.standard.double(forKey: "testAlertIn")
        if testDelay > 0 {
            let content = UNMutableNotificationContent()
            content.title = Prayer.asr.name
            content.body = "It's time for Asr · \(Date().addingTimeInterval(testDelay).formatted(date: .omitted, time: .shortened))"
            content.sound = .default
            content.interruptionLevel = AlertSettings.isTimeSensitive(.asr) ? .timeSensitive : .active
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: testDelay, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "test", content: content, trigger: trigger))
        }

        // Launch with `-logAlerts YES` to print every lined-up alert.
        if UserDefaults.standard.bool(forKey: "logAlerts") {
            // Written to Documents/pending-alerts.txt in the app's container.
            let pending = await center.pendingNotificationRequests()
            var lines = ["PENDING ALERTS: \(pending.count)"]
            for request in pending.sorted(by: { $0.identifier < $1.identifier }) {
                let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
                lines.append("  \(date?.formatted(date: .abbreviated, time: .shortened) ?? "soon") | \(request.content.title) | \(request.content.body) | \(request.content.interruptionLevel == .timeSensitive ? "time-sensitive" : "normal")")
            }
            try? lines.joined(separator: "\n").write(to: URL.documentsDirectory.appending(path: "pending-alerts.txt"), atomically: true, encoding: .utf8)
        }
        #endif
    }

    /// Schedules an alert at `date` (the real moment, so the Debug fake clock is accounted for).
    private func add(id: String, content: UNMutableNotificationContent, at date: Date, now: Date) async {
        let realDate = Date().addingTimeInterval(date.timeIntervalSince(now))
        guard realDate > Date() else { return }
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: realDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    // Show alerts as banners even while the app is on screen.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
