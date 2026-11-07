import Foundation

/// Fetches prayer times from the Aladhan API (ISNA method) for Lombard, IL.
nonisolated struct AladhanSource: PrayerTimesSource {
    var session: URLSession = .shared

    func fetchDays(from start: Date, count: Int) async throws -> [DayTimes] {
        let calendar = MasjidLocation.calendar
        let first = calendar.startOfDay(for: start)
        let dates = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }

        return try await withThrowingTaskGroup(of: DayTimes.self) { group in
            for date in dates {
                group.addTask { try await fetchDay(date) }
            }
            var days: [DayTimes] = []
            for try await day in group { days.append(day) }
            return days.sorted { $0.day < $1.day }
        }
    }

    private func fetchDay(_ date: Date) async throws -> DayTimes {
        let c = MasjidLocation.calendar.dateComponents([.year, .month, .day], from: date)
        let path = String(format: "%02d-%02d-%04d", c.day!, c.month!, c.year!)
        var components = URLComponents(string: "https://api.aladhan.com/v1/timings/\(path)")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(MasjidLocation.latitude)),
            URLQueryItem(name: "longitude", value: String(MasjidLocation.longitude)),
            URLQueryItem(name: "method", value: "2"),
        ]

        let (data, response) = try await session.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let timeZone = TimeZone(identifier: decoded.data.meta.timezone) ?? MasjidLocation.timeZone

        let raw = decoded.data.timings
        let pairs: [(Prayer, String)] = [
            (.fajr, raw.Fajr), (.sunrise, raw.Sunrise), (.dhuhr, raw.Dhuhr),
            (.asr, raw.Asr), (.maghrib, raw.Maghrib), (.isha, raw.Isha),
        ]
        let times = try pairs.map { prayer, text in
            PrayerTime(prayer: prayer, date: try Self.moment(text, on: c, in: timeZone))
        }
        let h = decoded.data.date.hijri
        let hijri = Int(h.day).flatMap { day in
            Int(h.year).map { HijriDate(day: day, month: h.month.number, year: $0) }
        }
        return DayTimes(day: String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!), times: times, hijri: hijri)
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
        let data: DayData
        struct DayData: Decodable {
            let timings: Timings
            let date: DateInfo
            let meta: Meta
        }
        struct DateInfo: Decodable {
            let hijri: Hijri
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
