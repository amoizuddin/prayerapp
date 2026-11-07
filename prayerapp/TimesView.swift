import SwiftUI

/// Today's prayer times, the next one highlighted, and a live countdown.
struct TimesView: View {
    /// Shared with the background refresh, which updates it while the app is closed.
    private let store = PrayerTimesStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let now = AppClock.now
                let gregorian = now.formatted(.dateTime.weekday(.wide).month(.wide).day())
                content(now: now)
                    .navigationTitle("Prayer Times")
                    .navigationSubtitle(gregorian)
                    .toolbar {
                        // Under the large title: the regular date, then the Hijri date
                        // (which switches to the next day at Maghrib), same size.
                        ToolbarItem(placement: .largeSubtitle) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(gregorian)
                                if let hijri = store.hijriDate(at: now) {
                                    Text(hijri.formatted)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Settings", systemImage: "gearshape") { showingSettings = true }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView { rescheduleAlerts() }
        }
        .task {
            await PrayerAlertScheduler.shared.requestPermission()
            await store.refreshIfNeeded(now: AppClock.now)
            rescheduleAlerts()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await store.refreshIfNeeded(now: AppClock.now)
                    rescheduleAlerts()
                }
            }
        }
        .onChange(of: store.days) { rescheduleAlerts() }
    }

    @State private var showingSettings = false
    /// Knows whether a finger is on the list (used to refresh only once it's let go).
    @State private var scrollTracker = ScrollTracker()

    /// Re-lines up the next week of prayer alerts from the current times and settings.
    private func rescheduleAlerts() {
        let days = store.days
        Task { await PrayerAlertScheduler.shared.reschedule(days: days, now: AppClock.now) }
    }

    /// Mail-style status: when the times were last updated, or that updating failed.
    /// For example "Updated just now", or "Couldn't connect · Updated 2 hours ago" after a failed refresh.
    private var statusLine: String {
        var updated = ""
        if let date = store.lastUpdated {
            updated = Date().timeIntervalSince(date) < 60
                ? "Updated just now"
                : "Updated \(date.formatted(.relative(presentation: .named)))"
        }
        guard store.lastError != nil else { return updated }
        return updated.isEmpty ? "Couldn't connect" : "Couldn't connect · \(updated)"
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let today = store.today(at: now) {
            let next = store.next(after: now)
            List {
                if let next {
                    Section {
                        CountdownRow(next: next, now: now)
                            .background(ScrollViewFinder(tracker: scrollTracker))
                    }
                }
                Section {
                    ForEach(today.times, id: \.self) { time in
                        PrayerRow(time: time, isNext: time == next)
                    }
                } header: {
                    Text("Today")
                } footer: {
                    Text(statusLine)
                }
            }
            .refreshable {
                // Spin while the finger is still down; fetch once it's let go
                // (with a 15-second safety limit so the spinner can never get stuck).
                let pulled = Date()
                while scrollTracker.isTouching && Date().timeIntervalSince(pulled) < 15 {
                    try? await Task.sleep(for: .milliseconds(50))
                }
                // Keep the spinner up for at least a second, so a fast refresh still reads as one.
                let started = Date()
                await store.refresh(now: AppClock.now)
                let remaining = 1 - Date().timeIntervalSince(started)
                if remaining > 0 { try? await Task.sleep(for: .seconds(remaining)) }
            }
        } else if store.isLoading {
            ProgressView("Loading prayer times…")
        } else {
            ContentUnavailableView {
                Label("Couldn't load prayer times", systemImage: "wifi.exclamationmark")
            } description: {
                Text("Check your internet connection and try again.")
            } actions: {
                Button("Retry") {
                    Task { await store.refresh(now: AppClock.now) }
                }
            }
        }
    }
}

private struct CountdownRow: View {
    let next: PrayerTime
    let now: Date

    var body: some View {
        let remaining = Duration.seconds(max(0, next.date.timeIntervalSince(now).rounded(.up)))
        VStack(alignment: .leading, spacing: 4) {
            Text("\(next.prayer.name) in")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(remaining.formatted(.time(pattern: .hourMinuteSecond)))
                .font(.largeTitle)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct PrayerRow: View {
    let time: PrayerTime
    let isNext: Bool

    var body: some View {
        HStack {
            if isNext {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Next")
            }
            Text(time.prayer.name)
                .fontWeight(isNext ? .semibold : .regular)
            Spacer()
            Text(time.date, format: .dateTime.hour().minute())
                .fontWeight(isNext ? .semibold : .regular)
                .monospacedDigit()
        }
        .foregroundStyle(isNext ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
    }
}

#Preview {
    TimesView()
}
