# Scrolodex

A macOS menu-bar app for switching between windows by scrolling.

Hold a modifier key and scroll to cycle through windows. Release to focus the selected one.

## Install

**Homebrew (prebuilt binary — recommended):**

```bash
brew install --cask jaydenfyi/tap/scrolodex
```

**Homebrew (build from source):**

```bash
brew install jaydenfyi/tap/scrolodex
```

Requires Xcode 15+ (`xcode-select --install`).

**Manual download:**

Download the latest `Scrolodex-x.x.x.zip` from [GitHub Releases](https://github.com/jaydenfyi/scrolodex/releases).
Unzip and move `Scrolodex.app` to `/Applications`.
On first launch, right-click the app and select **Open** to bypass Gatekeeper.

## Update

```bash
brew upgrade --cask jaydenfyi/tap/scrolodex
```

## Uninstall

```bash
brew uninstall --cask jaydenfyi/tap/scrolodex
```

## Permissions

On first launch, macOS will prompt for two permissions:

1. **Accessibility** — detect modifier keys and raise windows
2. **Screen Recording** — capture window thumbnails for the overlay

You can also grant these in **System Settings → Privacy & Security**.

> The app runs as a menu-bar item (no dock icon). Look for the scroll icon in the menu bar to confirm it's running.

## Default Triggers

| Trigger | Hotkey | Default |
|---|---|---|
| **Windows Under Cursor** | ⌥ scroll | ✅ On |
| **All Windows on Screen** | ⌘⌥ scroll | ✅ On |
| **Dock Windows** | Hover Dock icon + scroll | ✅ On |
| **Desktop Spaces** | Scroll at screen edge | Off |

Each trigger also supports **keyboard navigation** — step through windows with `` ⌥` `` (forward) and `` ⌥⇧` `` (backward) by default.

## Settings

Click the menu-bar icon → **Settings...** to configure:

- **General** — Launch at Login, scroll sensitivity
- **Triggers** — Enable/disable each trigger, set modifier keys, toggle overlay on press
- **Appearance** — Overlay mode (tooltip/list/tile), theme, window preview

## Requirements

- macOS 14 (Sonoma) or later

## Building from Source

```bash
git clone https://github.com/jaydenfyi/scrolodex.git
cd scrolodex
make build    # swift build
make app      # build + create .app bundle + codesign
make run      # build + launch
make test     # run tests (192 tests)
make release  # swift build -c release
```

## Architecture

| Target | Description |
|---|---|
| `Scrolodex` | AppKit entry point, overlay views, event taps, settings UI |
| `ScrolodexCore` | Platform-agnostic logic — navigation state, filtering, coordinate math |

`ScrolodexCore` has no AppKit dependency and is fully testable without a UI. The app target provides concrete implementations (event taps, window capture, overlay panels) via protocols defined in the core.

## License

MIT
