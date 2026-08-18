# TodoSticky

A tiny, always-on-top to-do list utility for macOS, modeled loosely on the built-in Stickies
app. It's a borderless floating panel — not a normal document window, and not a menu-bar
extra — that stays above every other window on every desktop Space.

## Features

- Floating panel that stays on top across all Spaces (`NSPanel`, `.floating` level,
  `.canJoinAllSpaces`), without stealing keyboard focus from whatever app was frontmost.
- No Dock icon / no Cmd+Tab entry (accessory app). Quit with **Cmd+Q** while the panel is
  focused, or right-click the title bar / collapsed bar for a "Quit TodoSticky" item.
- Drag to move via the title bar or the collapsed bar.
- Resizable from any edge or the bottom-right corner grip (with a wider, easier-to-grab hit
  area than the native thin borderless-window edge).
- **Double-click the title bar (or the collapsed bar) to collapse/expand.** Collapsed view
  shows "Tasks · N" plus a status dot: red if anything is overdue, yellow if anything is due
  within 5 hours, otherwise neutral.
- Checkboxes with strikethrough for completed items; completed items sink to the bottom,
  active items sort by due date (soonest first, undated last).
- Optional due date/time per item — quick picks (Today, Tomorrow, End of Week) or a custom
  date/time picker.
- One level of subtasks per item, with their own checkboxes, and a cancel ("×" or Escape) for
  the inline "add subtask" field.
- An explicit trash-icon button to delete a task (in addition to right-click delete).
- Text wraps dynamically as the window is resized; no horizontal scrolling. Vertical scrollbar
  when the list is taller than the window.
- Right-click the title bar / collapsed bar for **Theme** (System/Light/Dark), **Start at
  Login**, and **Quit**.
- Everything persists (tasks, subtasks, due dates, completion state, window position/size,
  collapsed/expanded state, theme) to `~/Library/Application Support/TodoSticky/` (plain JSON)
  and `UserDefaults` (theme), saved on every change.

## Requirements

- macOS 14 (Sonoma) or later.
- A Swift toolchain (Xcode 15+ or the Command Line Tools). No third-party dependencies —
  just Swift, SwiftUI, AppKit, and ServiceManagement (for the Login Item toggle).

## Build & install as a real app

```bash
cd TodoSticky
./build_app.sh
```

This builds a release binary, assembles `dist/TodoSticky.app`, ad-hoc code-signs it, and installs
it to `/Applications/TodoSticky.app`. Re-run this script any time you change the source to
rebuild and reinstall. Once installed, launch it like any other app — double-click it in
Finder/Launchpad, or:

```bash
open /Applications/TodoSticky.app
```

The app has no Dock icon and won't appear in Cmd+Tab (by design — it's an accessory app). To quit
it, focus the panel and press **Cmd+Q**, or right-click the title bar / collapsed bar and choose
**Quit TodoSticky**.

### Start at Login

Right-click the title bar (or the collapsed bar) and toggle **Start at Login**. This uses
`SMAppService` to register the app with macOS's login item system — no separate helper or
LaunchAgent file needed. The first time you enable it, macOS may require a one-time approval in
**System Settings → General → Login Items & Extensions**; the app will open System Settings to
that pane automatically if approval is needed. This only works for the installed
`/Applications/TodoSticky.app` copy, not a `swift run` debug binary.

### Development builds

For quick iteration without the full app-bundle step:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run
```

(The `DEVELOPER_DIR`/`xcrun` prefix is only needed if your machine's `xcode-select` default
toolchain is broken, as it was during initial development here — a full Xcode.app was installed
and pointed to explicitly instead of `sudo`-repairing the system Command Line Tools. If your
`swift build`/`swift run` already works normally, you can drop that prefix.) Note that Start at
Login won't work from a debug binary — only from the installed `.app`.

## Signing notes

`build_app.sh` ad-hoc code-signs the app (`codesign --sign -`), which is enough for Gatekeeper
to allow local launches without a warning and for `SMAppService`/Login Items to work reliably.
If you copy the `.app` to another Mac, Gatekeeper will likely show an "Apple could not verify..."
warning since it isn't signed with a real Developer ID; right-click → **Open** once to clear it.

## Sharing with someone else

```bash
./package_dmg.sh
```

Builds (if needed) and produces `dist/TodoSticky.dmg` — a standard disk image with the app and
an `Applications` shortcut, so opening it gives the usual drag-to-Applications install flow.
Send that one file (Slack, AirDrop, email, etc.).

Two things the recipient needs to know:

- **Apple Silicon only.** This build isn't a universal binary — it won't run on an Intel Mac.
- **First-launch Gatekeeper warning.** Since it's only ad-hoc signed (no paid Apple Developer
  ID / notarization), macOS will likely say it "cannot be opened because Apple cannot verify it
  is free of malware" the first time. They should right-click the app in Finder → **Open**, then
  confirm in the dialog — only needed once. (On a corporate/managed Mac, endpoint security
  software may also flag a freshly-built unsigned app; if so, that's a security-tooling review,
  not an app bug — same thing happened during development here with SentinelOne.)

## Project layout

```
Info.plist                  Bundle metadata (LSUIElement, bundle ID, etc.) used by build_app.sh
build_app.sh                 Builds, signs, and installs the .app to /Applications
package_dmg.sh               Packages the .app into a shareable dist/TodoSticky.dmg
Sources/TodoSticky/
  TodoStickyApp.swift        App entry point (SwiftUI App + NSApplicationDelegateAdaptor)
  AppDelegate.swift          Sets accessory activation policy, creates the panel
  LoginItemManager.swift     SMAppService wrapper for the Start at Login toggle
  Panel/                     AppKit panel, drag, and resize plumbing
  Models/                    TodoItem, Subtask, DueDateQuickOption, AppTheme
  Store/                     TodoStore (state + sorting) and JSON/UserDefaults persistence
  Views/                     SwiftUI views (title bar, list, rows, add field, due date menu)
```
