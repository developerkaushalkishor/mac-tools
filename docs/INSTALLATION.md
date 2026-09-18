# Install and update ScreenInk

## For non-developers

There is no published notarized GitHub Release yet, so the repository's green **Code → Download ZIP** button downloads source code rather than an installable application. Wait for a release that provides a `ScreenInk-<version>-macOS-<architecture>.zip` file plus its `.sha256` checksum. That public artifact must be Developer ID-signed, Apple-notarized and verified on a clean Mac before this guide recommends installing it.

The steps below are currently for developers or users comfortable building from source. Do not disable Gatekeeper globally or run quarantine-removal commands copied from issue comments.

## Requirements

- macOS 14+ is the declared deployment target. The current validated build environment is Apple Silicon, macOS 26.6.2, Xcode 27 and Swift 6.4. Other supported-by-declaration OS/toolchain combinations and Intel need verification.
- Swift 6 or newer, macOS SDK, Git and code-signing tools. Full [Xcode](https://developer.apple.com/xcode/resources/) is the recommended setup.
- Enough disk space for your chosen Xcode installation and local build output.

There are no third-party Swift packages, API keys or server services to configure. Internet access is needed to download tools and clone/update the repository; the app itself works offline.

## 1. Prepare Xcode

Install Xcode from Apple's official source. Open it once, review and accept its license yourself, and finish the first-launch setup. The built-in macOS SDK is sufficient; iOS, watchOS, tvOS and visionOS simulator downloads are not required.

The scripts prefer `/Applications/Xcode.app/Contents/Developer` if it exists. Otherwise, they use the selected system toolchain. An explicitly set `DEVELOPER_DIR` takes precedence. For an alternate Xcode location:

```bash
export DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer"
```

Replace that example with the actual developer directory. The scripts do not change your system-wide `xcode-select` setting. Command Line Tools may also build the app if they include a compatible Swift 6 compiler and SDK, but full Xcode is the recommended contributor environment.

## 2. Clone, check and build

Run these commands from the parent folder where you want to keep the source:

```bash
git clone https://github.com/developerkaushalkishor/mac-tools.git
cd mac-tools
bash scripts/doctor.sh
bash scripts/test.sh
bash scripts/build.sh
```

The expected result is `dist/ScreenInk.app`. Build output targets the host Mac's architecture; this is not a universal binary build. The first build can take longer while Apple framework modules are cached.

## 3. Launch

From the repository root:

```bash
open dist/ScreenInk.app
```

Alternatively, `bash scripts/run.sh` builds and opens the app in one command. Find the pen-and-ink icon in the macOS menu bar; no Dock icon is expected. The toolbar may auto-hide after two seconds. Use the menu icon's **Show Toolbar** command or hover near the display's top-center edge.

To keep the app independently of your source checkout, quit ScreenInk and use Finder to copy `dist/ScreenInk.app` into your user Applications folder (`~/Applications`) or the system Applications folder. Create the user Applications folder if needed. If an older copy exists, replace it deliberately after quitting it. Launch the copied app rather than retaining multiple running copies.

The local build is ad-hoc signed and includes the ScreenInk application icon. There is no downloadable installer, Homebrew formula or notarized release provided by this project yet. Maintainers can create a local test archive or follow the guarded Developer ID/notarization workflow in [RELEASING.md](RELEASING.md). Do not disable Gatekeeper globally. If macOS reports a blocked or damaged app, record the exact message, confirm the source and rebuild locally before reporting the issue.

## 4. Use and update

Read [USAGE.md](USAGE.md) before drawing. Annotations are in memory only, so finish your session before quitting or updating.

For an unmodified checkout on `main`:

```bash
git status --short
git pull --ff-only
bash scripts/test.sh
bash scripts/build.sh
open dist/ScreenInk.app
```

If `git status` shows changes, preserve your work before pulling. If the pull cannot fast-forward, stop and resolve the branch state; do not reset or discard changes just to update. Quit the existing app before rebuilding. If you installed a copy in Applications, copy the new build there again and launch that copy.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Swift or SDK not found | Run `bash scripts/doctor.sh`; complete Xcode setup and check `DEVELOPER_DIR` |
| Package requires a newer tools version | The manifest requires Swift 6; update the Apple toolchain |
| Xcode license/first-launch error | Open Xcode and finish the required setup interactively |
| No toolbar or Dock icon | This is a menu-bar app; use its pen-and-ink icon → Show Toolbar |
| Drawing intercepts ordinary clicks | Press Escape or choose Toggle Drawing; manual Hide Toolbar also exits drawing mode |
| Toolbar saved on a missing display | Use menu icon → Reset Toolbar to Top Center |
| Old behavior after rebuilding | Quit the existing process and reopen the freshly built app; check for an older Applications copy |
| Screenshot remains unavailable | Screenshot support is experimental. Record the exact macOS permission state and error; other annotation tools remain usable without Screen Recording access |
| App is unresponsive | Quit ScreenInk using Activity Monitor; unsaved annotations will be lost |

ScreenInk requests Screen Recording permission only when you use its experimental screenshot tool. The permission flow is not yet reliable on the current test Mac. Do not grant Accessibility or other broad privacy permissions as generic troubleshooting steps.

## Uninstall

Quit ScreenInk, then move your installed `ScreenInk.app` to the Trash. If you only ran from the checkout, the app is in `dist`. Removing the app does not remove the source repository or its saved toolbar preferences. No background service or login item is installed by these scripts.
