# PaulBunyan

[![Tests](https://github.com/tedslittlerobot/PaulBunyan/actions/workflows/tests.yml/badge.svg)](https://github.com/tedslittlerobot/PaulBunyan/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Day-by-day log files for macOS apps, ready to zip up and hand to whoever's helping.

PaulBunyan sets up [XCGLogger](https://github.com/DaveWoodCom/XCGLogger) loggers so that each
one writes to its own file, in a folder for the day, in a folder for your app:

```
~/.logs/
└── my-app/                 ← named in your Info.plist
    ├── 2026-11-05/
    └── 2026-11-06/         ← a folder for each day; the newest 10 are kept
        ├── installer.log   ← a file for each logger
        ├── network.log
        └── sparkler.log
```

It also lists those days, zips a day up, and gives you a SwiftUI button that copies the zip or
drags it straight into an email or a chat message, so a user can send you their logs in one
click.

- One line to make a logger: `LogFolder.current.makeLogger(named: "installer")`
- The folder is set once, in your app's `Info.plist`, not at every call site
- Every logger also writes to the system log, so Console.app and `log stream` show it
- Old days are cleared out automatically
- Each launch is marked in the file, so you can tell sessions apart
- `Transferable`, so a day of logs can be dragged anywhere that takes a file

## Requirements

- macOS 26 or later
- Swift 6.2 or later (Xcode 26 or later)

## Installation

### Xcode

Choose **File › Add Package Dependencies…**, enter the repository's URL, and add the
`PaulBunyan` library to your app's target:

```
https://github.com/tedslittlerobot/PaulBunyan
```

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/tedslittlerobot/PaulBunyan", from: "2.0.0"),
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "PaulBunyan", package: "PaulBunyan"),
            // Only if you name XCGLogger's types yourself, such as XCGLogger.Level:
            .product(name: "XCGLogger", package: "XCGLogger"),
        ],
    ),
],
```

PaulBunyan depends on [XCGLogger](https://github.com/DaveWoodCom/XCGLogger) 7.1.5 or later,
which comes with it.

## Quick start

1. Name your app's log folder in its `Info.plist`:

   ```xml
   <key>PaulBunyanLogFolderName</key>
   <string>my-app</string>
   ```

   In Xcode, that's a row in the target's **Info** tab: key `PaulBunyanLogFolderName`, type
   String, value `my-app`.

2. Make a logger, and log:

   ```swift
   import PaulBunyan

   enum Log {
       static let installer = LogFolder.current.makeLogger(named: "installer")
   }

   Log.installer.info("Installing Homebrew")
   // → ~/.logs/my-app/2026-11-06/installer.log
   ```

3. Let people send you their logs:

   ```swift
   if let today = LogFolder.current.today() {
       ShareLogsButton(day: today)
   }
   ```

## Naming your app's log folder

`LogFolder.current` is your app's folder, `~/.logs/<name>`. It works out `<name>` from the main
bundle, taking the first of these it finds:

| Source | Example | Folder |
| --- | --- | --- |
| The `PaulBunyanLogFolderName` Info.plist key, as it is | `my-app` | `~/.logs/my-app` |
| The bundle's `CFBundleName`, lowercased with hyphens for spaces | `My App` | `~/.logs/my-app` |
| The bundle's executable's name, lowercased with hyphens for spaces | `MyApp` | `~/.logs/myapp` |
| Nothing at all | | `~/.logs/app` |

Characters other than letters, digits, `.`, `_` and `-` become hyphens, and leading and
trailing hyphens and dots are dropped, so the name is always a single folder inside `~/.logs`.

Setting the key is worth it even when the bundle's name would do, so that renaming the app
doesn't move its logs.

### Helper apps

A helper inside your app's bundle, such as a menu bar app, a login item or an XPC service, is a
bundle of its own with its own name, so by default it logs to a folder of its own. To keep all
of an app's logs together, give the helper's `Info.plist` the same `PaulBunyanLogFolderName` as
the app's. Give its loggers different names from the app's (`menu-bar.log`, say), since two
processes appending to one file interleave their lines.

### A folder of your own choosing

Make a `LogFolder` yourself to log somewhere else, such as a temporary folder in tests:

```swift
let folder = LogFolder(name: "my-app")                                    // ~/.logs/my-app
let folder = LogFolder(name: "my-app", home: temporaryDirectory)          // <temp>/.logs/my-app
let folder = LogFolder(name: "my-app", daysKept: 30)                      // keep a month
let folder = LogFolder(bundle: helperBundle)                              // named by another bundle
```

`LogFolder` is a small `Sendable` value. Nothing is created on disk until a logger is made.

## Making loggers

```swift
let logger = LogFolder.current.makeLogger(named: "installer")
```

`makeLogger(named:level:date:)` returns an `XCGLogger` that writes to:

- **`<name>.log` in today's folder.** If the file's already there, because the app has logged
  to it earlier today, the logger appends to it after a `RELAUNCH` marker.
- **The system log**, through `NSLog`, which Console.app and `log stream` show.

It creates today's folder if it isn't there, and deletes the oldest days beyond those kept
(see [Old logs](#old-logs)). Its first lines describe the app: its name, version, build and
process ID.

| Parameter | Default | |
| --- | --- | --- |
| `named` | | The logger's name, and its file's: `installer` writes `installer.log` |
| `level` | `.debug` | The least severe level it logs. `.verbose` lines are left out unless you pass `.verbose` |
| `date` | now | The day whose folder it writes to |

Use XCGLogger's methods to log, from least to most severe:

```swift
logger.verbose("Checked /opt/homebrew/bin/brew")
logger.debug("PATH is \(path)")
logger.info("Installing Homebrew")
logger.notice("Homebrew was already installed")
logger.warning("Homebrew is slow to respond")
logger.error("Installing Homebrew failed: \(error)")
logger.severe("Can't write to /usr/local")
```

See [XCGLogger's documentation](https://github.com/DaveWoodCom/XCGLogger) for everything else
a logger can do.

### One logger per part of the app

Each logger gets its own file, so make one for each part of your app that someone might need to
look into on its own, and name it so related files sort together:

```swift
enum Log {
    static let installer = LogFolder.current.makeLogger(named: "installer")
    static let network = LogFolder.current.makeLogger(named: "network")

    static func dependency(_ name: String) -> XCGLogger {
        LogFolder.current.makeLogger(named: "dependency.\(name)")   // dependency.homebrew.log
    }
}
```

Make each logger once and keep it, in a `static let` or a long-lived object. Each call to
`makeLogger` opens the file again and writes a `RELAUNCH` marker and the app's details.

### A logger runs for the life of the app

A logger keeps writing to the folder of the day it was made in. An app that runs for days, such
as a menu bar app, carries on writing to the first day's file. Make a new logger to start
writing to a new day's folder.

### Sharing a logger between threads

`XCGLogger` isn't marked `Sendable`, so Swift 6 won't let a plain `static let` logger be used
from more than one isolation domain. In a target whose default isolation is the main actor,
a `static let` is main-actor isolated, which is all most app code needs.

To use one logger from anywhere, mark it `nonisolated(unsafe)`:

```swift
enum Log {
    nonisolated(unsafe) static let network = LogFolder.current.makeLogger(named: "network")
}
```

That's safe as long as you only log with it, and don't change its configuration (its level,
destinations or formatters) after making it:

- `makeLogger` finishes configuring the logger before it returns it, and a `static let` is
  initialised once, so nothing changes it after it's published;
- the system log destination writes with `NSLog`, which is thread-safe;
- the file destination writes on XCGLogger's serial `logQueue`, so writes to a file never
  overlap;
- PaulBunyan's formatter keeps no state between lines.

## What the logs look like

In a log file, each line has the time, the level, the file and line it was logged from, and the
function:

```
2026-11-06 09:15:02.118 [Info] > My App Version: 1.4.0 Build: 212 PID: 31830
2026-11-06 09:15:02.118 [Info] > XCGLogger Version: 7.1.5 - Level: Debug
2026-11-06 09:15:02.118 [Info] > XCGLogger writing log to: file:///Users/jdoe/.logs/my-app/2026-11-06/installer.log
2026-11-06 09:15:02.240 [Info] [Installer.swift:42] run() > Installing Homebrew
2026-11-06 09:15:09.731 [Error] [Installer.swift:57] run() > Installing Homebrew failed: exit status 1


----------========== RELAUNCH ==========----------

2026-11-06 11:02:44.007 [Info] > My App Version: 1.4.0 Build: 212 PID: 40211
```

In the system log, each entry is headed by the time, the level with an emoji, the logger's name
and the function, then the file and line, then the message:

```
[09:15:02] [ℹ️ Info] [installer] [run()]
[Installer.swift:42]

Installing Homebrew
```

| Level | Emoji |
| --- | --- |
| Verbose | |
| Debug | 👾 |
| Info | ℹ️ |
| Notice | 📔 |
| Warning | ⚠️ |
| Error | 🔥 |
| Severe | 🔥🔥 |
| Alert | 🔥🔥🔥 |
| Emergency | 🔥⚡️🔥⚡️ |

### Reading them

```sh
# Follow a log file
tail -f ~/.logs/my-app/$(date +%F)/installer.log

# Follow the system log for your app
log stream --predicate 'process == "My App"' --style compact
```

## Old logs

Each time a logger is made, the folder's oldest day folders are deleted, keeping the newest 10
(`LogFolder.defaultDaysKept`). Pass `daysKept:` to keep more or fewer. Only folders named by
date (`2026-11-06`) count as days; anything else in the folder is left alone.

To clear out old days without making a logger, call `removeExpiredDays()`.

Day folders are named in the user's current time zone.

## Browsing and sharing logs

### Days

```swift
let folder = LogFolder.current

folder.url             // ~/.logs/my-app
folder.days            // [LogDay], newest first, read from disk each time
folder.today()         // LogDay? — nil until something has logged today
folder.folder(for: d)  // the URL a day's logs are (or will be) in
folder.showInFinder()  // opens ~/.logs/my-app in Finder
```

A `LogDay` is one day's folder:

```swift
day.url                // ~/.logs/my-app/2026-11-06
day.date               // the start of that day
day.isToday()          // whether it's today
day.logFiles           // its .log files, by name
day.showInFinder()     // opens its folder in Finder
```

### Zips

```swift
let zip = try day.makeArchive()          // ~/Downloads/my-app.2026-11-06.jdoe.zip
let zip = try day.makeArchive(in: folder) // somewhere else
try day.copyArchive()                     // makes the zip, then copies it, ready to paste
```

The zip is named `<folder>.<day>.<user>.zip`, so whoever receives it knows whose logs they are,
and holds the day's folder with its log files. It's made with `/usr/bin/ditto`, and replaces an
older zip of the same day. `makeArchive` waits for `ditto` to finish, so call it off the main
thread if the folder might be large. It throws `LogDay.ArchiveError.zipFailed` if `ditto`
can't make the zip, such as when the day's folder has gone.

### Dragging

`LogDay` is `Transferable`: it exports a zip of itself. So in SwiftUI, a day can be dragged into
Mail, Slack, Finder or anything else that takes a file:

```swift
Label(day.date.formatted(date: .abbreviated, time: .omitted), systemImage: "doc.zipper")
    .draggable(day)
```

### The share button

`ShareLogsButton` does both: click it to copy a zip of the day's logs (it reads **Copy Logs**,
**Zipping…**, then **Copied**), or drag it to drop the zip somewhere. It zips off the main
thread.

```swift
ShareLogsButton(day: day)
```

### A log explorer

Put together, a settings panel that lists each day's logs:

```swift
import PaulBunyan
import SwiftUI

struct LogsPanel: View {
    @State private var days: [LogDay] = []

    var body: some View {
        Form {
            Section {
                LabeledContent("Location", value: LogFolder.current.url.path)
                Button("Show in Finder") { LogFolder.current.showInFinder() }
            }

            Section("Logs by Day") {
                if days.isEmpty {
                    Text("Nothing has been logged yet.")
                }

                ForEach(days) { day in
                    LabeledContent(day.isToday() ? "Today" : day.date.formatted(date: .complete, time: .omitted)) {
                        Button("Show in Finder") { day.showInFinder() }
                        ShareLogsButton(day: day)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { days = LogFolder.current.days }
    }
}
```

## Upgrading from 1.x

1.x always logged to `~/.logs/dan`. 2.0 logs to the app's own folder, named in its
`Info.plist`. To keep logging to the same folder, set `PaulBunyanLogFolderName` to `dan`
(an app whose bundle is named DAN already logs to `~/.logs/dan` without it).

| 1.x | 2.0 |
| --- | --- |
| `LoggerFactory.shared.create(named:)` | `LogFolder.current.makeLogger(named:)`. The old call still works, but is deprecated |
| `LogDirectoryJanitor.shared` | `LogFolder.current` |
| `janitor.baseDirectory` | `folder.url` |
| `janitor.prepareAndGetLogDirectory()` | `folder.folder(for: Date())`, which no longer creates it; making a logger does |
| `janitor.logClusters` | `folder.days` (already sorted, newest first) |
| `logClusters.forToday` | `folder.today()` |
| `logClusters.sortedByDate` | `folder.days` |
| `LogCluster` | `LogDay` |
| `cluster.isToday` | `day.isToday()` |
| `cluster.friendlyDate` | `day.date.formatted(date: .abbreviated, time: .omitted)` |
| `cluster.openInFinder()` | `day.showInFinder()` |
| `cluster.makeArchive()` | `try day.makeArchive()`, which now throws if it can't make the zip |
| `cluster.copyArchiveUrl()` | `try day.copyArchive()` |
| `cluster.ShareButton` | `ShareLogsButton(day: day)` |
| Dragging a `LogCluster` exported a file URL | Dragging a `LogDay` exports the zip itself |

Zips are now named after the app's log folder (`my-app.2026-11-06.jdoe.zip`), not always `dan.…`,
and the system log no longer trims a `DatabaseAccessNexus/` prefix from file paths: it shows just
the file's name. 2.0 no longer depends on ZipArchive.

## Development

```sh
swift build
swift test
swift test --filter "LogDay archives"                  # one suite or test, by its name
swift format -i -r Sources Tests Package.swift         # format, using .swift-format
swift format lint --strict -r Sources Tests Package.swift
```

GitHub Actions runs the build, the tests and the format check on every push to `main` and every
pull request (`.github/workflows/tests.yml`).

Releases are semver tags on `main` (`2.0.0`). Conventions for working on the package, for
people and coding agents alike, are in [`CLAUDE.md`](CLAUDE.md).

## Licence

PaulBunyan is released under the MIT Licence. See [`LICENSE`](LICENSE).
