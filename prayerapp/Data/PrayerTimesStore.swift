import Foundation
import Observation

/// Holds the prayer times the app shows: loads the saved copy first, then refreshes from the source.
@Observable
final class PrayerTimesStore {
    private(set) var days: [DayTimes] = []
    private(set) var isLoading = false
    private(set) var lastError: Error?

    private let source: any PrayerTimesSource
    private let cache: PrayerTimesCache
    private let daysToFetch = 7

    init(source: any PrayerTimesSource = AladhanSource(), cache: PrayerTimesCache = PrayerTimesCache()) {
        self.source = source
        self.cache = cache
        self.days = cache.load()
    }

    /// Today's six times, if we have them.
    func today(at now: Date) -> DayTimes? {
        let key = MasjidLocation.dayKey(for: now)
        return days.first { $0.day == key }
    }

    /// The next time (Sunrise included) after `now`, looking into the coming days if needed.
    func next(after now: Date) -> PrayerTime? {
        days.flatMap(\.times).filter { $0.date > now }.min { $0.date < $1.date }
    }

    /// Fetches fresh times unless we already hold enough days ahead.
    func refreshIfNeeded(now: Date) async {
        let tomorrow = MasjidLocation.calendar.date(byAdding: .day, value: 1, to: now)!
        let haveToday = today(at: now) != nil
        let haveTomorrow = days.contains { $0.day == MasjidLocation.dayKey(for: tomorrow) }
        if haveToday && haveTomorrow && lastFetchDay == MasjidLocation.dayKey(for: now) { return }
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
            lastFetchDay = MasjidLocation.dayKey(for: now)
            lastError = nil
        } catch {
            lastError = error
        }
    }

    private var lastFetchDay: String?
}
