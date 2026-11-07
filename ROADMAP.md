# Roadmap

## Now
- **Lock Screen widget** (paused): next prayer and time, plus time remaining in hours and minutes (rectangular), or "Asr 2:18 PM" (inline). Waiting on adding a Widget Extension target named `PrayerWidget` in Xcode (File → New → Target → iOS → Widget Extension, all three "Include" boxes unchecked).

## Next
- **Azan and widget:** the azan as the notification sound (under 30 seconds, bundled as `.caf`), and a Lock Screen widget for the next prayer.
- **IF iqamah times:** swap in Islamic Foundation's actual times (and ideally its announced Hijri date) once a source is available.

## Ideas
- **Live Activity:** an always-visible Lock Screen / Dynamic Island card, e.g. "Asr · not yet prayed", until the prayer is marked done. Note: starting one automatically at prayer time needs a server sending a push; without one it can only start while the app is open. Lasts at most about 8 hours.
- **Mark as prayed:** a "Prayed" button on each alert, with follow-up reminders every so often until pressed. Follow-ups count toward the 64-alert limit.
- **Reminder before each prayer:** e.g. 10 minutes before.
- **Per-prayer alert on/off switches** (in the settings screen).
- **Hijri date adjustment:** shift the Hijri date by ±1 day to match IF's moon-sighting date.
- **Home Screen widget:** a bigger widget that could show all of today's times, alongside the Lock Screen widget.
- **Salah tracker:** a simple daily checklist of the five prayers to tick off as each is prayed. Details to be fleshed out; could tie in with "Mark as prayed" above (the alert's "Prayed" button checking it off).

## Done
- **Times screen:** today's five prayers plus Sunrise, the next one highlighted, and a live countdown. Times cached for offline use.
- **Hijri date:** from Aladhan, shown under the regular date, switching to the next day at Maghrib.
- **Pull-to-refresh:** spins while held, fetches when let go, with a status line ("Updated just now" / "Couldn't connect · Updated 2 hours ago").
- **Prayer alerts:** a local alert at each of the five prayers (not Sunrise), 12 days ahead (iOS caps queued alerts at 64), refilled whenever the app opens, wakes, or refreshes.
  - Each prayer can be set to Time Sensitive (breaks through Focus modes) in Settings (gear button).
  - A "running low" reminder about a day before alerts run out: "Don't miss a prayer" / "Open Salah to keep getting alerts."
- **Background refresh and month-at-a-time data:** about 30 days of times per fetch (Aladhan's month endpoint); the app goes online only when fewer than 13 days remain (about every 2½ weeks). iOS is asked to wake the app every 3 days to refill alerts from saved times. Best effort: iOS may delay or skip it (Low Power Mode, Background App Refresh off, app swiped away), which the 12 days of alerts cover.
- **App name:** shown as "Salah" on the Home Screen and in iOS prompts.
