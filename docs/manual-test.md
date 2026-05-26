# Scrolodex Manual Test Notes

## Build

Run unit tests:

```bash
swift test
```

Build the executable:

```bash
swift build
```

Build and run a local app bundle:

```bash
make run
```

## Permissions

On first launch, open **Settings** from the menu-bar icon and request Accessibility permission. If macOS does not show the prompt, open System Settings -> Privacy & Security -> Accessibility and enable Scrolodex manually.

During local development macOS may reset Accessibility permission when the app bundle is rebuilt. Toggle Scrolodex off and on again in Accessibility settings if the event tap stops working.

## Window Navigation

1. Open two or more overlapping normal app windows.
2. Move the cursor over the overlap.
3. Hold **Command + Option** (the default trigger) and scroll to cycle through windows.
4. Confirm the selected window with left-click while holding the trigger, or release the trigger to focus the selected window.
5. Press Escape while holding the trigger to cancel.

The default triggers are:

- **Command + Option** — windows under cursor
- **Command + Option + Control** — all windows on screen

Configure triggers in **Settings** from the menu-bar icon. Each trigger row supports scope (under cursor / on screen), filter (all apps / same app), and monitor scope (this screen / all screens).

## Desktop Switching

Hold **Option + Shift** (default) and scroll to switch between macOS Spaces. Enable and configure in Settings under the Desktop Switching section.

## Dock Hover

Enable Dock Hover in Settings to navigate windows of a specific app by scrolling over its Dock icon while holding a modifier key. Supports current-monitor and all-monitors scopes.

## Overlay Appearance

Configure overlay mode (tooltip, tile, or list), theme (dark or light), peek previews, and animation in the Appearance section of Settings.

## Debugging

Useful live log command:

```bash
/usr/bin/log stream --predicate "eventMessage CONTAINS 'Scrolodex'" --style compact
```
