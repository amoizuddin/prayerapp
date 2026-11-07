import SwiftUI

/// Today's prayer times, the next one highlighted, and a live countdown.
struct TimesView: View {
    @State private var store = PrayerTimesStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let now = AppClock.now
                content(now: now)
                    .navigationTitle("Prayer Times")
                    .navigationSubtitle(now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            }
        }
        .task { await store.refreshIfNeeded(now: AppClock.now) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.refreshIfNeeded(now: AppClock.now) }
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let today = store.today(at: now) {
            let next = store.next(after: now)
            List {
                if let next {
                    Section {
                        CountdownRow(next: next, now: now)
                    } header: {
                        // The Hijri date; switches to the next day at Maghrib.
                        if let hijri = store.hijriDate(at: now) {
                            Text(hijri.formatted)
                        }
                    }
                }
                Section("Today") {
                    ForEach(today.times, id: \.self) { time in
                        PrayerRow(time: time, isNext: time == next)
                    }
                }
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
