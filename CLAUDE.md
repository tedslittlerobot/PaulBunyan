# CLAUDE.md

Guidance for Claude Code (and anyone else) working on this repository.

## Project

**PaulBunyan** is a small Swift package for macOS apps. It sets up
[XCGLogger](https://github.com/DaveWoodCom/XCGLogger) loggers that write to
`~/.logs/<app>/<yyyy-MM-dd>/<logger>.log` and to the system log, rotates old days out, and zips a
day's logs to share (with a SwiftUI button and `Transferable` drag support). It's public: the
`README.md` is its user documentation, so keep it accurate whenever behaviour or API changes.

- One library product and module, `PaulBunyan`, in `Sources/PaulBunyan/`.
- One dependency, XCGLogger. Don't add others without asking.
- macOS 26+, Swift 6.2 tools, Swift 6 language mode, with the upcoming features in
  `Package.swift`'s `[SwiftSetting].standard` (`ExistentialAny`, `InternalImportsByDefault`,
  `MemberImportVisibility`, `NonisolatedNonsendingByDefault`, `InferIsolatedConformances`).

## Commands

```sh
swift build
swift test
swift test --filter "LogFolder loggers"                # one suite or test, by its display name
swift format -i -r Sources Tests Package.swift         # format everything
swift format lint --strict -r Sources Tests Package.swift   # must pass; CI runs it
```

CI (`.github/workflows/tests.yml`) builds, tests and lints on pushes to `main` and on pull
requests, on GitHub's `macos-26` runners.

## Layout

| File | What it is |
| --- | --- |
| `LogFolder.swift` | The public entry point. An app's folder: naming (Info.plist key `PaulBunyanLogFolderName`, then `CFBundleName`, then the executable), day folders, listing days, `makeLogger(named:level:date:)`, rotation |
| `LogFolder+Finder.swift` | `showInFinder()` |
| `LogDay.swift` | One day's folder: its date, log files, zipping with `/usr/bin/ditto`, copying the zip |
| `LogDay+Transferable.swift` | Dragging a day exports its zip |
| `ShareLogsButton.swift` | The SwiftUI copy-or-drag button |
| `LogDestinations.swift` | Internal. The system log and file destinations every logger gets |
| `LogLineFormatter.swift` | Internal. The system log's line format |
| `LoggerFactory.swift` | Deprecated 1.x shim, forwarding to `LogFolder.current` |

## Conventions

- **British English** in identifiers, doc comments, comments and messages, except where a Swift
  or platform API is spelled the American way.
- **Follow the Swift API Design Guidelines.** Write the call site first. Factory methods start
  with `make`. Booleans read as assertions (`isToday`). Default arguments over overloads,
  defaulted parameters last.
- **Default to `internal`.** Only make something `public` when a caller needs it. Use
  `public import` only for modules whose types appear in public API (Foundation, XCGLogger,
  AppKit, CoreTransferable, SwiftUI).
- **Every public declaration gets a doc comment**, saying what it does, not how. The main entry
  points have a usage example.
- **Make side effects injectable for tests.** Take `home:` folders, `now:`/`date:` and
  pasteboards as parameters with sensible defaults, as `LogFolder.init(name:home:daysKept:)`,
  `makeLogger(named:level:date:)` and `copyArchive(to:in:)` do.
- **Modern Swift.** Use `URL.appending(path:)`, `Date.FormatStyle` and Swift Regex, never
  `DateFormatter` or force-unwraps in library code. Use typed errors with `LocalizedError`
  descriptions.
- **One primary type per file.** Put extensions in `Type+Topic.swift`.
- **Formatting is `.swift-format`** (4 spaces, 120 columns). Run the formatter before
  committing.
- **Concurrency.** Value types are `Sendable`. Anything touching AppKit (`NSWorkspace`,
  `NSPasteboard`) is `@MainActor`. Blocking work, such as `ditto`, is synchronous and
  documented as such. The button moves it off the main thread with a `@concurrent` function.
  `XCGLogger` isn't `Sendable`. The README explains when sharing one is safe; keep that
  explanation true if the logger's configuration changes.

## Tests

- Use Swift Testing. Suites and tests have raw-identifier names that read as sentences
  (``@Suite struct `LogDay archives` ``, ``@Test func `replace an older zip of the same day`() ``).
  Don't name a suite exactly after a type, or it shadows the type inside the suite.
- **Never touch the real home folder, `~/.logs` or `~/Downloads`.** Use the fixtures in
  `Tests/PaulBunyanTests/Support/TestFixtures.swift`:
  - `TemporaryDirectory`, a throwaway home folder;
  - `TemporaryBundle`, an app bundle with a given Info.plist;
  - `Date.noon(on:)`, a date safely inside a named day in any time zone;
  - `URL.loggedText()`, which waits for XCGLogger's queue before reading a log file.

  The one exception is the `Transferable` test, which has to export to `~/Downloads`. It uses a
  unique folder name and deletes its zip.
- Test behaviour through the public API where possible. Internal helpers (`folderName(from:)`,
  `LogLineFormatter.line(…)`) are tested directly with `@testable import`.
- Every behaviour change needs a test, and every public API change needs the README updated,
  including the "Upgrading" section for anything that breaks callers.

## Releasing

Releases are semver git tags on `main`. Breaking changes are a new major version, with a
migration table in the README and, where it's cheap, a deprecated shim.

## Don'ts

- Don't create tags, push, or publish releases. The maintainer does that.
- Don't add dependencies without asking.
- Don't commit `.build/`, `.swiftpm/` user state or `.DS_Store` (see `.gitignore`).
