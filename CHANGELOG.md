# Changelog
## 0.0.4 (2026-05-30)

### Features

- add ScrolodexSettings target, move SettingKey to new module
- add TriggerSettingCatalog with shipped entries
- add RuntimeConfiguration and UserDefaultsRuntimeConfigurationReader
- add TriggerContext.from(gestureConfig:) and replace inline construction
- add peekEnabled, peekOpacity, theme to DockHoverConfiguration

### Fixes

- use catalog defaultModifierFlags in dock hover builder
- Make `registerDefaults` catalog-driven.
- Centralize trigger prefixes in catalog.
- Add cursor-following overlay repositioning: the tooltip tracks the mouse position during an active navigation session instead of staying fixed at the trigger point.
- Fix cursor move: revert sync dispatch to async to prevent AX-I/O hangs, allow single-window candidate refresh during cursor relocation, skip first-move spurious candidate query until a meaningful position is established, and align peek border radius to standard macOS windows (10pt).
- Improve cursor-following: lightweight reposition path that avoids full overlay rebuild, selection preservation across cursor relocation, smooth tooltip interpolation, and single-candidate repositioning fix.
- Extract `ScrolodexSettings` module from AppDelegate.
- Standardize desktop switch settings to use catalog prefix.
- Unify TriggerContext construction: add `.from(gestureConfig:)`, move peek/theme fields into `DockHoverConfiguration`, simplify `DockActionHandler`.

## 0.0.3 (2026-05-26)

### Features

- add app icon

## 0.0.2 (2026-05-26)

### Fixes

- app crash on launch — use Bundle.main for menu bar icon

## 0.0.1 (2026-05-26)

### Fixes

- resource bundle not found on launch

## 0.0.0 (2026-05-26)

### Fixes

- Appearance stays at bottom, Triggers between General and Appearance
- remove versioned Homebrew syntax for knope
