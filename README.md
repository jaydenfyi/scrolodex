<div align="center">

# scrolodex

**a super simple window switcher for macOS**

Hold ⌥ (Option) and scroll to cycle through windows under your cursor. Release to focus the selected one.

https://github.com/user-attachments/assets/246eab14-c8ed-4164-b5a3-3e89ee4e3738

</div>

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

**Build from source:**

```bash
git clone https://github.com/jaydenfyi/scrolodex.git
cd scrolodex
make app      # build + create .app bundle + codesign
make run      # launch
```

Requires Xcode 15+ (`xcode-select --install`).

> **Note:** The app is ad-hoc signed (no Apple Developer ID). macOS will warn that it can't verify the developer.
> The Homebrew cask handles this automatically by clearing the quarantine flag.
> For manual installs, use the right-click → **Open** shortcut on first launch:
> 1. **Right-click** (secondary click) `Scrolodex.app` in Finder and select **Open**
> 2. Click **Open** in the dialog — this bypasses Gatekeeper for this launch only
> 3. If the "Open" button isn't shown, go to **System Settings → Privacy & Security** and click **Open Anyway** next to the "Scrolodex was blocked" message
> Alternatively, run `xattr -cr /Applications/Scrolodex.app` in Terminal.

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

1. **Accessibility** — detect modifier keys (⌘⌥⌃⇧) and raise (focus) the selected window via the Accessibility API
2. **Screen Recording** — capture window thumbnails for the list/tile overlay modes

You can also grant these in **System Settings → Privacy & Security**.

> The app runs as a menu-bar item (no dock icon). Look for the scroll icon in the menu bar to confirm it's running.

---

## Quick Start

The default configuration covers the most common workflows out of the box:

| Trigger | Modifier | What it does |
|---|---|---|
| **Windows Under Cursor** | Hold ⌥ + scroll | Cycle through windows beneath the pointer |
| **All Windows** | Hold ⌘⌥ + scroll | Cycle every visible window on the active display |
| **Dock Windows** | Hover a Dock icon, hold ⌥ + scroll | Cycle the hovered app's windows |

You can also step through windows using keyboard navigation:

| Binding | Default | What it does |
|---|---|---|
| Forward | `` ⌥` `` (Option + backtick) | Select next window |
| Backward | `` ⌥⇧` `` (Option + Shift + backtick) | Select previous window |
| Escape | `⎋` | Cancel the session |

> Press the keyboard binding **without** holding the scroll modifier to activate the trigger and step immediately (keyboard-only activation).

---

## Settings Overview

Click the menu bar icon → **Settings...**

### General

| Setting | Default | Description |
|---|---|---|
| Launch at Login | Off | Register as a macOS Login Item |
| Scroll Sensitivity | 6 (1–20) | Higher = more responsive |

### Triggers

| Trigger | Default Modifier | Description |
|---|---|---|
| **Windows Under Cursor** | ⌥ + scroll | Cycle windows beneath the pointer. |
| **All Windows** | ⌘⌥ + scroll | Cycle all visible windows on the active display. |
| **Dock Windows** | Hover + ⌥ + scroll | Cycle the hovered app's windows. Overlay anchors to the Dock icon. |
| **Desktop Spaces** | ⌥⇧ + scroll (disabled) | Switch between desktop Spaces. |

### Appearance

| Setting | Default | Description |
|---|---|---|
| Theme | System | Dark / Light — follows macOS appearance |
| Show Window Preview | On | Border outline first, snapshot thumbnail at 50–100% opacity |
| Animate scrolling | On | Overlay transition animations |
| Wrap around | On | Scroll past last window wraps to first |

### Overlay Modes

| Mode | Description |
|---|---|
| **Tooltip** *(default)* | Small badge near cursor — window title, app icon, position counter |
| **List** | Vertical rows with thumbnails, selection highlight, animated scroll |
| **Tile** | Horizontal scrolling tiles with thumbnails |
| **None** | No overlay, only the window preview highlight |

---

## Requirements

- **macOS 14 (Sonoma)** or later
- **Accessibility permission** — detect modifier keys, raise/focus windows
- **Screen Recording permission** — window thumbnails for list/tile overlays and window preview

---

## License

MIT