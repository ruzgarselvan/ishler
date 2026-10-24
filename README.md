# ishler

A tiny task app for your menu bar (macOS) and your phone (iPhone). You type a sentence, it works out the person, the task and the date, and reminds you when it's time.

> "Cuma'ya kadar X müşterisine teklif at" → person: X · task: teklif at · due: Friday

Made for people whose tasks get lost between notes, calendars and ten different lists (ADHD-friendly by design). Free and open source. Turkish and English.

## What it does

- **One sentence, no forms.** Dates ("tomorrow", "Friday", "24 November", "in 3 days"), times ("17:30", "5pm"), repeats ("every Monday", "her ayın 15'i") and people are understood in Turkish and English. Works fully on-device, no server and no AI service.
- **Categories with shortcuts.** End a note with `x` or `(x)` to file it under a category; each category has its own colour and its own optional reminders.
- **Recurring tasks** that put themselves back on your list (monthly invoice on the 15th, weekly plan…), with checklists.
- **Reminders that don't nag.** Evenings before a deadline, the morning of, and a nudge only if you've been away for a while. Done / snooze buttons right on the notification.
- **Apple Calendar** in both directions, widgets, a focus screen ("just this, now"), Siri / Shortcuts, Spotlight, CSV export.
- **Syncs through your own iCloud.** Your tasks never touch a server of mine.

## Install (Mac)

Download the latest `.dmg` from [Releases](../../releases), open it and drag **ishler** to Applications. The app is signed and notarized by Apple.

## Build from source

Requires Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
xcodegen generate
open MenuBarTodo.xcodeproj
```

The parsing, scheduling and storage logic lives in the `TodoCore` Swift package and has its own tests:

```sh
cd TodoCore && swift test
```

To run your own build you'll need to change the team, bundle identifiers and iCloud container in `project.yml` to your own.

## License

MIT
