import Foundation
import Observation

/// Holds the prayer times the app shows: loads the saved copy first, then refreshes from the source.
@Observable
final class PrayerTimesStore {
    /// The one store the app uses, shared by the screen and background refresh.
    static let shared = PrayerTimesStore()

    private(set) var days: [DayTimes] = []
    private(set) var isLoading = false
    private(set) var lastError: Error?
    /// Real (wall-clock) time of the last successful update.
    private(set) var lastUpdated: Date?

    private let source: any PrayerTimesSource
    private let cache: PrayerTimesCache
    /// How many days each fetch covers (about a month, usually two requests to Aladhan).
    private let daysToFetch = 30
    /// Go online only when fewer saved days than this remain (today included):
    /// enough to always line up 12 days of alerts.
    private let minimumDaysAhead = 13

    init(source: any PrayerTimesSource = PrayerTimesStore.defaultSource, cache: PrayerTimesCache = PrayerTimesCache()) {
        self.source = source
        self.cache = cache
        self.days = cache.load()
        self.lastUpdated = days.isEmpty ? nil : cache.lastSaved()
    }

    /// Aladhan normally. In Debug builds, launching with `-simulateOffline YES`
    /// makes every fetch fail, to test the offline behavior.
    private static var defaultSource: any PrayerTimesSource {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "simulateOffline") { return OfflineSource() }
        #endif
        return AladhanSource()
    }

    /// Today's six times, if we have them.
    func today(at now: Date) -> DayTimes? {
        let key = MasjidLocation.dayKey(for: now)
        return days.first { $0.day == key }
    }

    /// The Hijri date right now. The Islamic day begins at Maghrib, so after
    /// today's Maghrib this is tomorrow's Hijri date.
    func hijriDate(at now: Date) -> HijriDate? {
        guard let today = today(at: now) else { return nil }
        let maghrib = today.times.first { $0.prayer == .maghrib }?.date
        guard let maghrib, now >= maghrib else { return today.hijri }
        let tomorrow = MasjidLocation.calendar.date(byAdding: .day, value: 1, to: now)!
        let key = MasjidLocation.dayKey(for: tomorrow)
        return days.first { $0.day == key }?.hijri
    }

    /// The next time (Sunrise included) after `now`, looking into the coming days if needed.
    func next(after now: Date) -> PrayerTime? {
        days.flatMap(\.times).filter { $0.date > now }.min { $0.date < $1.date }
    }

    /// Number of saved days from today onward (0 if today itself is missing).
    func daysAhead(at now: Date) -> Int {
        guard today(at: now) != nil else { return 0 }
        let todayKey = MasjidLocation.dayKey(for: now)
        return days.filter { $0.day >= todayKey }.count
    }

    /// Goes online only when the saved times can't fill 12 days of alerts,
    /// so the app normally fetches about once every two and a half weeks.
    func refreshIfNeeded(now: Date) async {
        guard daysAhead(at: now) < minimumDaysAhead else { return }
        await refresh(now: now)
    }

    func refresh(now: Date) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await source.fetchDays(from: now, count: daysToFetch)
            let yesterday = MasjidLocation.dayKey(for: MasjidLocation.calendar.date(byAdding: .day, value: -1, to: now)!)
            var byDay = Dictionary(uniqueKeysWithValues: days.map { ($0.day, $0) })
            for day in fresh { byDay[day.day] = day }
            days = byDay.values.filter { $0.day >= yesterday }.sorted { $0.day < $1.day }
            cache.save(days)
            lastUpdated = Date()
            lastError = nil
        } catch {
            lastError = error
        }
    }
}

#if DEBUG
/// A source that always fails, as if there were no internet.
private nonisolated struct OfflineSource: PrayerTimesSource {
    func fetchDays(from start: Date, count: Int) async throws -> [DayTimes] {
        try await Task.sleep(for: .seconds(4))
        throw URLError(.notConnectedToInternet)
    }
}
#endif
