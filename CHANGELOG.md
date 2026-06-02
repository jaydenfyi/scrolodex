# Changelog
## 0.0.11 (2026-06-02)

### Fixes

- Append "(debug)" to the version string in Settings for debug builds.
- Recreate Gesture Trigger HID event tap after timeout or user-input disable instead of re-enabling the dead mach port.
- Log Gesture Trigger event tap disable/re-enable events and fail fast when its run loop source cannot be created.
- Recreate event taps on wake and session re-activation to recover from silent gesture tap death after sleep.

## 0.0.10 (2026-06-01)

### Fixes

- Add Gesture Trigger settings for choosing vertical or horizontal three- and four-finger swipes.
- Restrict Gesture Trigger navigation to vertical swipes by locking gesture intent before starting navigation.

## 0.0.9 (2026-06-01)

### Fixes

- Collapse duplicate `releaseGesture`/`cancelGesture` cleanup paths into a single `endGesture` method so gesture session state stays in sync.
- Reset stale Gesture Trigger tracking when inactive touch snapshots fall below the configured finger count so later trackpad swipes can activate reliably.

## 0.0.8 (2026-06-01)

### Fixes

- stateful touch tracking for session lifecycle
- consume scroll during active session
- Consume scroll events while an external Window Navigation Session is active so Gesture Trigger navigation does not leak inertial scroll into the active app.
- Enlarge Tooltip app icons to fill more of the badge height and keep the compact container padding balanced.
- Fix Trackpad Gesture session lifecycle: stateful touch tracking keeps sessions alive through finger-count transitions (partial lift), extra-finger touch cancels the session immediately, and deferred 80ms release handles ambiguous empty snapshots during transitions.
- Update GitHub Actions to Node.js 24-compatible versions: actions/checkout v6.0.2, actions/upload-artifact v7.0.1, actions/download-artifact v8.0.1.

## 0.0.7 (2026-05-31)

### Fixes

- Reduce desktop switch gate duration for instant (non-animated) mode from 180ms to 80ms, allowing ~12 switches/second instead of ~5.5.
- Fix Trackpad Gesture activation by observing the full gesture event lifecycle and counting stationary fingers that remain down during a swipe.
- Keep the Tooltip overlay attached to cursor movement while a Trackpad Gesture navigation session remains active after lifting to one finger.

## 0.0.6 (2026-05-31)

### Fixes

- Fix window stack not refreshing when cursor crosses monitors during active session. Remove `.underCursor`-only guard from cursor relocation refresh so all scope types update candidates on cross-monitor movement.
- Keep the Desktop Switch overlay pinned to the cursor while a desktop trigger is active.
- Show app names for full-screen Desktop Switch targets and avoid inventing duplicate Desktop labels for unlabeled Spaces.
- Keep the Desktop Switch overlay following the cursor when switching between a full-screen Space and a regular Desktop.
- Fix Desktop Switch targeting the focused display instead of the display under the cursor. Space metadata now resolves per display, no-op boundaries keep showing the current Desktop label, and synthesized Dock swipe events carry the cursor location.
- Improve Desktop Switch scroll precision by preserving excess scroll delta and blocking overlapping synthetic swipe sequences.

## 0.0.5 (2026-05-30)

### Fixes

- Fix cursor move overlay appearing before first scroll when `showOnPress` is disabled. Clear `lastCandidateCursor` on session end to prevent stale state leaking across trigger activations.

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
