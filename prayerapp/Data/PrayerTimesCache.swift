import Foundation

/// Saves prayer times on the device so the app works offline.
nonisolated struct PrayerTimesCache {
    private let fileURL: URL

    init(fileName: String = "prayer-times.json") {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appending(path: fileName)
    }

    func load() -> [DayTimes] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([DayTimes].self, from: data)) ?? []
    }

    func save(_ days: [DayTimes]) {
        guard let data = try? JSONEncoder().encode(days) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
