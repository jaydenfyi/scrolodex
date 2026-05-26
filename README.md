# Scrolodex

A macOS menu-bar app that lets you switch between windows by scrolling.

Hold a modifier key and scroll to cycle through the window stack under your cursor, across your screen, or within the same app. Release to focus the selected window.

## Features

- **Windows under cursor** — scroll the stack beneath the pointer
- **All windows on screen** — cycle every visible window
- **Same-app filtering** — limit switching to the frontmost app
- **Dock icon hover** — scroll over Dock icons to switch that app's windows
- **Desktop switching** — scroll between macOS Spaces
- **Keyboard navigation** — step through windows with custom key bindings
- **Trackpad gestures** — 3- and 4-finger swipe triggers
- **Overlay modes** — tooltip badge, vertical list, or horizontal tile view
- **Dark and light themes** — with peek previews and border highlights

## Install

**Homebrew (build from source):**

```bash
brew tap jaydenfyi/tap
brew install scrolodex
```

**Homebrew (prebuilt binary):**

```bash
brew tap jaydenfyi/tap
brew install --cask scrolodex
```

**Manual:**

Download the latest release from [GitHub Releases](https://github.com/jaydenfyi/scrolodex/releases).
Unzip and move `Scrolodex.app` to `/Applications`.
On first launch, right-click the app and select **Open** to bypass Gatekeeper.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode command-line tools (`xcode-select --install`)

## Building from source

```bash
make build    # swift build
make app      # build + create .app bundle + codesign
make run      # build + launch the app
make test     # run tests
make release  # swift build -c release
make clean    # remove .build
```

## Permissions

Scrolodex requires two system permissions:

1. **Accessibility** — to detect modifier keys and raise windows
2. **Screen Recording** — to capture window thumbnails for previews

The app will prompt on first launch. You can also grant them manually in **System Settings → Privacy & Security**.

## Architecture

| Target | Description |
|---|---|
| `Scrolodex` | AppKit entry point, overlay views, event taps, settings UI |
| `ScrolodexCore` | Platform-agnostic logic — navigation state, filtering, coordinate math |

`ScrolodexCore` has no AppKit dependency and is fully testable without a UI. The app target provides the concrete implementations (event taps, window capture, overlay panels) via protocols defined in the core.

## License

MIT
