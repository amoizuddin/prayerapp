# Roadmap

## Now
- **Prayer alerts:** a local alert at each of the five prayers (not Sunrise), a week ahead (iOS caps queued alerts at 64), refilled whenever the app opens or refreshes.
  - Each prayer can be set to Time Sensitive (breaks through Focus modes) in an in-app settings screen.
  - A "running low" reminder about a day before alerts run out: "Don't miss a prayer" / "Open Prayer Times to keep getting alerts."
- **Background refresh:** the app asks iOS to wake it about twice a day to fetch fresh times and refill alerts. Best effort: iOS skips it in Low Power Mode, when Background App Refresh is off, after the app is swiped away, or for rarely used apps.

## Next
- **Azan and widget:** the azan as the notification sound (under 30 seconds, bundled as `.caf`), and a Lock Screen widget for the next prayer.
- **IF iqamah times:** swap in Islamic Foundation's actual times (and ideally its announced Hijri date) once a source is available.

## Ideas
- **Live Activity:** an always-visible Lock Screen / Dynamic Island card, e.g. "Asr · not yet prayed", until the prayer is marked done. Note: starting one automatically at prayer time needs a server sending a push; without one it can only start while the app is open. Lasts at most about 8 hours.
- **Mark as prayed:** a "Prayed" button on each alert, with follow-up reminders every so often until pressed. Follow-ups count toward the 64-alert limit.
- **Reminder before each prayer:** e.g. 10 minutes before.
- **Per-prayer alert on/off switches** (in the settings screen).
- **Hijri date adjustment:** shift the Hijri date by ±1 day to match IF's moon-sighting date.

## Done
- **Times screen:** today's five prayers plus Sunrise, the next one highlighted, and a live countdown. Times cached for offline use.
- **Hijri date:** from Aladhan, shown under the regular date, switching to the next day at Maghrib.
- **Pull-to-refresh:** with a status line ("Updated just now" / "Couldn't connect · Updated 2 hours ago").
