import Foundation

/// Fetches prayer times from the Aladhan API (ISNA method) for Lombard, IL.
/// Uses the month endpoint (`/v1/calendar/{year}/{month}`): one request per calendar month.
nonisolated struct AladhanSource: PrayerTimesSource {
    var session: URLSession = .shared

    func fetchDays(from start: Date, count: Int) async throws -> [DayTimes] {
        let calendar = MasjidLocation.calendar
        let first = calendar.startOfDay(for: start)
        let last = calendar.date(byAdding: .day, value: count - 1, to: first)!
        let firstKey = MasjidLocation.dayKey(for: first)
        let lastKey = MasjidLocation.dayKey(for: last)

        // The calendar months the requested days fall in (usually two).
        var months: [(year: Int, month: Int)] = []
        var cursor = calendar.date(from: calendar.dateComponents([.year, .month], from: first))!
        while cursor <= last {
            let c = calendar.dateComponents([.year, .month], from: cursor)
            months.append((c.year!, c.month!))
            cursor = calendar.date(byAdding: .month, value: 1, to: cursor)!
        }

        var days: [DayTimes] = []
        for (year, month) in months {
            days += try await fetchMonth(year: year, month: month)
        }
        return days
            .filter { $0.day >= firstKey && $0.day <= lastKey }
            .sorted { $0.day < $1.day }
    }

    private func fetchMonth(year: Int, month: Int) async throws -> [DayTimes] {
        var components = URLComponents(string: "https://api.aladhan.com/v1/calendar/\(year)/\(month)")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(MasjidLocation.latitude)),
            URLQueryItem(name: "longitude", value: String(MasjidLocation.longitude)),
            URLQueryItem(name: "method", value: "2"),
        ]

        // Always ask Aladhan: it allows reusing answers for an hour, which would make a
        // refresh return old data instantly. The app keeps its own saved copy instead.
        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return try decoded.data.map(Self.dayTimes)
    }

    private static func dayTimes(from entry: Response.DayData) throws -> DayTimes {
        let timeZone = TimeZone(identifier: entry.meta.timezone) ?? MasjidLocation.timeZone

        // Gregorian date comes as "DD-MM-YYYY".
        let parts = entry.date.gregorian.date.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { throw URLError(.cannotParseResponse) }
        let day = DateComponents(year: parts[2], month: parts[1], day: parts[0])

        let raw = entry.timings
        let pairs: [(Prayer, String)] = [
            (.fajr, raw.Fajr), (.sunrise, raw.Sunrise), (.dhuhr, raw.Dhuhr),
            (.asr, raw.Asr), (.maghrib, raw.Maghrib), (.isha, raw.Isha),
        ]
        let times = try pairs.map { prayer, text in
            PrayerTime(prayer: prayer, date: try moment(text, on: day, in: timeZone))
        }
        let h = entry.date.hijri
        let hijri = Int(h.day).flatMap { d in
            Int(h.year).map { HijriDate(day: d, month: h.month.number, year: $0) }
        }
        let key = String(format: "%04d-%02d-%02d", parts[2], parts[1], parts[0])
        return DayTimes(day: key, times: times, hijri: hijri)
    }

    /// Turns "05:13" or "05:13 (CST)" on a given day into an exact moment.
    private static func moment(_ text: String, on day: DateComponents, in timeZone: TimeZone) throws -> Date {
        let parts = text.prefix(5).split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            throw URLError(.cannotParseResponse)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = day
        components.hour = hour
        components.minute = minute
        guard let date = calendar.date(from: components) else { throw URLError(.cannotParseResponse) }
        return date
    }

    private struct Response: Decodable {
        let data: [DayData]
        struct DayData: Decodable {
            let timings: Timings
            let date: DateInfo
            let meta: Meta
        }
        struct DateInfo: Decodable {
            let gregorian: Gregorian
            let hijri: Hijri
        }
        struct Gregorian: Decodable {
            let date: String
        }
        struct Hijri: Decodable {
            let day: String
            let month: Month
            let year: String
            struct Month: Decodable { let number: Int }
        }
        struct Timings: Decodable {
            let Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha: String
        }
        struct Meta: Decodable {
            let timezone: String
        }
    }
}
