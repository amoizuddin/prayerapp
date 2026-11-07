//
//  prayerappApp.swift
//  prayerapp
//
//  Created by Abdullah Moizuddin on 11/7/26.
//

import SwiftUI

@main
struct prayerappApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PrayerAlertScheduler.shared.activate()
        #if DEBUG
        // Launch with `-runBackgroundRefresh YES` to run the background refresh once at launch,
        // since the simulator won't wake the app on its own.
        if UserDefaults.standard.bool(forKey: "runBackgroundRefresh") {
            Task { await BackgroundRefresh.run() }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            TimesView()
        }
        .onChange(of: scenePhase) { _, phase in
            // Each time the app goes to the background, ask for a wake-up about 3 days later.
            if phase == .background { BackgroundRefresh.schedule() }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await BackgroundRefresh.run()
        }
    }
}
