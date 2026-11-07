# Prayer Times (iOS)

A personal iPhone app showing daily prayer times for Islamic Foundation (IF) in Villa Park, IL, with a countdown and an alert at each prayer. It's a stepping stone toward a larger home device that runs on masjid data, so keep the code clean enough to reuse.

## How I work
- I don't read or write code. I judge the app by using it. Explain changes in plain English: what changed and what I should see.
- Plan before building. For any new feature, give me a short plan and wait for my OK.
- Keep changes small: one feature at a time, testable on its own.
- After every change, build and run the app in the iPhone simulator with `xcodebuild`. Fix compile errors yourself before reporting back.
- Commit to git after each working feature with a clear message.
- Don't add anything I didn't ask for. Suggest it instead.

## Design rules
- SwiftUI only. Use Apple's standard components (List, Form, NavigationStack, TabView, system fonts, SF Symbols) so the app looks and feels native.
- Follow Apple's Human Interface Guidelines. No custom colors, fonts, or styling unless I ask.
- Support Dark Mode and Dynamic Type from the start.
- Target the latest iOS release only. No backward-compatibility code.

## Tech rules
- Apple frameworks only. Ask before adding any third-party package.
- Prayer data: Aladhan API (`api.aladhan.com/v1/timings`), ISNA method (`method=2`), location Lombard, IL.
- Cache the times locally so the app works offline.
- Keep data fetching separate from the UI, so the source can be swapped for IF's real iqamah times later.

## Roadmap
1. **Times screen:** today's five prayers plus sunrise, the next prayer highlighted, and a live countdown.
2. **Notifications:** a local alert at each prayer. iOS caps queued alerts at 64, so schedule a few days ahead and refill on launch.
3. **Azan and widget:** the azan as the notification sound (under 30 seconds, bundled as `.caf`), and a Lock Screen widget for the next prayer.
4. **IF iqamah times:** swap in IF's actual times once a source is available.
