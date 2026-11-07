//
//  prayerappApp.swift
//  prayerapp
//
//  Created by Abdullah Moizuddin on 11/7/26.
//

import SwiftUI

@main
struct prayerappApp: App {
    init() {
        PrayerAlertScheduler.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            TimesView()
        }
    }
}
