# ColimaUI

A macOS menu bar app that shows Colima status and lets you start or stop Colima from the menu. When Colima is running, it also shows running vs total Docker containers.

## Requirements

- macOS
- [Colima](https://github.com/abiosoft/colima) installed (e.g. via Homebrew: `brew install colima`)
- Docker (used by Colima; typically available when Colima is running)

## Build & Run

1. Open `ColimaUI.xcodeproj` in Xcode.
2. Select the **ColimaUI** scheme and your Mac as the run destination.
3. Press **⌘R** to build and run.

To run tests: **⌘U** (or Product → Test). The **ColimaUITests** target tests `ColimaState` and ColimaService parsing (colima status output and container count line).

The app appears as an icon in the menu bar (green when Colima is running, red when stopped). Use the menu to start or stop Colima, or quit the app.

## CI (GitHub Actions)

A workflow in `.github/workflows/build-dmg.yml` builds the app and creates a DMG on push or PR to `main`/`master`, and on manual run (**Actions → Build and create DMG → Run workflow**). The DMG is uploaded as an artifact (**Actions → run → Artifacts**). The build uses the runner’s default Xcode and sets `MACOSX_DEPLOYMENT_TARGET=14.0` so it succeeds on GitHub’s macOS runners.

## Distribution

You can build the app in Xcode and distribute the `.app` (e.g. in a ZIP or DMG)—no Apple Developer Program required. The app is not sandboxed (so it can run the Colima CLI) and therefore cannot be submitted to the Mac App Store.

**First launch:** macOS may show "ColimaUI is from an unidentified developer." The user can **right-click the app → Open** and then click **Open** in the dialog, or allow it once in **System Settings → Privacy & Security**. After that, the app opens normally. There is no free way to remove this one-time prompt without a paid Apple Developer account (which provides signing and notarization).

## License

See the repository for license information.
