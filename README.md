# ColimaUI

A macOS menu bar app that shows Colima status and lets you start or stop Colima from the menu. When Colima is running, it shows running vs total Docker containers; you can click **Containers** to open a window listing all containers and start or stop them from the list.

## Requirements

- macOS
- [Colima](https://github.com/abiosoft/colima) installed (e.g. via Homebrew: `brew install colima`)
- Docker (used by Colima; typically available when Colima is running)

## Build & Run

1. Open `ColimaUI.xcodeproj` in Xcode.
2. Select the **ColimaUI** scheme and your Mac as the run destination.
3. Press **⌘R** to build and run.

To run tests: **⌘U** (or Product → Test). The **ColimaUITests** target tests parsing and validation used by ColimaService and Container (colima status, container count, container list, display name, running status, and safe container ID).

The app appears as an icon in the menu bar (green when Colima is running, red when stopped). Use the menu to start or stop Colima, open the Containers window, or quit the app.

## Download

Pre-built DMGs are available on the [Releases](../../releases) page. Download the latest `ColimaUI-vX.Y.Z.dmg`, open it, and drag the app to your Applications folder.

**First launch:** macOS may show "ColimaUI is from an unidentified developer." Right-click the app → **Open**, then click **Open** in the dialog, or allow it in **System Settings → Privacy & Security**.

## CI / Releases (GitHub Actions)

- **`build-dmg.yml`** — builds and tests on every push to `main`; uploads a DMG as a temporary artifact.
- **`release.yml`** — triggers on `v*` tags; builds, tests, and publishes a permanent GitHub Release with the DMG attached.

To cut a release: push a version tag (e.g. `git tag v1.0.0 && git push origin v1.0.0`).

## Distribution

The app is not sandboxed (so it can run the Colima CLI) and cannot be submitted to the Mac App Store. No Apple Developer Program is required to build or distribute it.

## License

See the repository for license information.
