# Scrolodex

A macOS menu-bar app for switching between windows by scrolling. Domain language for the Scrolodex codebase.

## Language

**Trigger** (umbrella):
A configuration that can activate a window navigation session. Four concrete types:

- **Hotkey Trigger** — activated by holding a modifier key combination (e.g. ⌘⌥). Supports three interaction modes: **modifier + scroll** (hold modifier, scroll to cycle), **modifier + keyboard step** (hold modifier, press forward/backward key to step), and **keyboard-only activation** (press the keyboard binding directly without holding the scroll modifier — the Event Router activates the trigger automatically). Configures scope, filter, overlay mode, peek settings, theme, monitor scope, animation, wrap-around, invert direction, showOnPress, and keyboard navigation bindings.
- **Gesture Trigger** — activated by a trackpad swipe (3 or 4 fingers). Same settings as Hotkey Trigger minus keyboard bindings and showOnPress. Handled by a separate HID event tap (`TrackpadGestureObserver`).
- **Dock Trigger** — activated by hovering over a Dock icon while holding a modifier. Scope is always `.dockHover`, filter always `.sameApp`. Overlay anchors at the Dock icon position rather than the cursor. Supports scroll and keyboard step navigation while hovered.
- **Desktop Trigger** — activated by holding a modifier key for switching macOS Spaces. Configures animation velocity, invert direction, wrap-around, and keyboard navigation bindings. No scope/filter/overlay/peek settings — it's purely for space switching.

*Avoid:* hotkey (use only for the raw key flags `HotkeyConfiguration`), shortcut

**Trigger Context**:
The resolved configuration for an active navigation session — scope, filter, overlay mode, peek enabled/opacity, theme, monitor scope, animation settings, wrap-around, invert direction, scroll threshold, and optional Dock bundle identifier. Produced from any Trigger type or a Dock Hover configuration. Consumed uniformly by the Navigation Coordinator.
*Avoid:* trigger state, active config

**Window Candidate**:
A visible window parsed from the CGWindowList API, carrying: CG window ID, owner PID, owner name, window title, bounds (CGRect), CoreGraphics layer number, and alpha value.
*Avoid:* window, target window

**Window Stack**:
The ordered list of Window Candidates collected for a navigation session. Filtered by scope (under cursor, on screen, or dock hover), filter (all apps or same app), and monitor scope (current monitor or all monitors).
*Avoid:* candidate list, window list

**Navigation Session**:
An active selection cycle through a Window Stack. Tracks the current selection index and accumulated scroll delta. Applies a configurable scroll threshold (pixels of scroll before selection advances) and optional wrap-around. Produces `SelectionMovement` (none, or changed with direction and wrap flag), and can be confirmed (returns the selected `WindowCandidate`) or cancelled. Also supports direct keyboard stepping via `step(direction:)`.
*Avoid:* session (unqualified), selection state

**Overlay**:
The cursor-anchored or Dock-anchored selection UI that shows the Window Stack. Three presentation modes:
- **Tooltip** — small floating badge near cursor/selection showing window title, app icon, position dots, and counter
- **List** — vertical rows with window thumbnails, selection highlight, and animated scroll transitions
- **Tile** — horizontal scrolling tiles with window thumbnails and selection highlight

A separate **Desktop Switch overlay** shows space name, position, and total spaces during desktop switching. The Overlay and Peek are shown simultaneously during a session.
*Avoid:* popup, HUD, UI

**Peek**:
A visual overlay positioned at the selected window's actual screen bounds, faking the window being raised to the top. Shows either a **border highlight** (colored outline, used on initial selection per the Peek Presentation Policy) or a **snapshot thumbnail** of the window's contents at configurable opacity. Spatially distinct from the Overlay — the Peek is tied to the window's position, the Overlay is tied to cursor or Dock icon.
*Avoid:* preview (ambiguous with trigger preview), snapshot overlay

**Peek Presentation Policy**:
Decides whether to show a border-only or snapshot peek for a given selection. Border-only is used for initial selections outside Dock Hover to avoid a visual flash — the first selection shows a border, subsequent selections show snapshots.

**Desktop Switch**:
Navigating between macOS Spaces by synthesizing dock swipe events (`CGSEventDockControl`). Configurable with animated or instant scroll velocity, invert direction, and wrap-around at space boundaries. Tracks the current space index via SkyLight private APIs. Produces a `SpaceSwitchResult` (requested/effective direction, from/to space indices, total space count) and an `OverlayModel` for the desktop switch overlay.

**Dock Hover**:
Navigating windows of a specific application by scrolling over its Dock icon while holding a modifier. Uses an `AXObserver` on the Dock's `AXList` to track which icon is currently hovered (bundle identifier, process ID, item frame). The anchor point for overlay positioning is calculated from the Dock icon's frame via `DockGeometry`.
*Avoid:* dock trigger, dock scroll (use Dock Hover for the feature, dock scroll only for the specific scroll-delta action)

**Trigger Scope**:
Where Window Candidates are collected from: `underCursor` (windows whose bounds contain the cursor), `currentScreen` (all visible windows on the active display), or `dockHover` (windows of the hovered Dock app).

**Trigger Filter**:
Which windows to include in the Window Stack: `allApps` or `sameApp` (only the frontmost application).

**Monitor Scope**:
Which displays to collect windows from: `currentMonitor` or `allMonitors`. Applied when scope is `currentScreen` or `dockHover`.

**Event Router**:
A stateful classifier that processes raw input events (`RouterEvent`) and current Dock state (`DockHoverInput`) against the active session state, producing a `(RouterDirective, RouterAction)` pair. The **directive** controls event propagation (pass through, consume, consume and pass through, stop tap, re-enable tap). The **action** is a domain-specific enum — `WindowAction` (activate, scroll, click-confirm, release, keyboard navigate, escape cancel), `DesktopAction` (activate, switch, released), `DockAction` (activate, scroll, preview, keyboard navigate, released), or `SystemAction` (permissions lost). Maintains mutable state: active trigger, active desktop trigger, dock session active flag, and desktop scroll accumulator.

**Navigation Coordinator**:
The central orchestrator (`@MainActor`). Receives actions from the Event Router and manages the lifecycle of Navigation Sessions: activating trigger contexts, collecting Window Candidates via the `WindowStackProvider`, starting/updating sessions on scroll or keyboard input, confirming selections (which raises the target window via the Accessibility API `WindowRaiser`), refreshing the candidate list on cursor relocation, and cancelling sessions.

**Keyboard Navigation**:
Stepping through the Window Stack using key bindings instead of scrolling. Configured per trigger with a `KeyboardNavigationBinding` (forward/backward key combos with flags + key code). Three usage contexts:
- **Hotkey Trigger**: while the scroll modifier is held, press the binding to step; or press the binding standalone to activate the trigger and step immediately (keyboard-only activation).
- **Dock Trigger**: while hovered over a Dock icon, press the binding to step through that app's windows.
- **Desktop Trigger**: press the binding to switch spaces directly.

**Overlay Anchor Session**:
Tracks the persistent anchor point for overlay positioning during Dock Hover sessions. The anchor is captured from the Dock icon's frame when the session starts and held until the session ends or resets. Prevents the overlay from jumping when the cursor moves within the same Dock icon.

**Trigger Release Behavior**:
Determines what happens when a trigger modifier is released. If a Navigation Session is active, releases confirm the current selection. If no session is active, the overlay hides. Controlled by `TriggerReleaseBehavior.action(hasActiveSession:)`.

**Dock Action Handler**:
A shared `@MainActor` component (`DockActionHandling` protocol) that processes `DockAction` cases by constructing a `TriggerContext` from the dock configuration and current UserDefaults (peek opacity, theme), then bridging to the Navigation Coordinator. Centralizes the UserDefaults reads that were previously duplicated across EventTapController and TrackpadGestureObserver. Accepts `scrollThreshold` at construction time (does not vary per action).

## Relationships

- A **Trigger** (Hotkey, Gesture, Dock, or Desktop) produces a **Trigger Context** when activated
- A **Trigger Context** determines the **Trigger Scope**, **Trigger Filter**, and **Monitor Scope** for collecting **Window Candidates**
- The **Event Router** receives raw CG input events, tracks active trigger state, and produces actions consumed by the **Navigation Coordinator**
- The **Navigation Coordinator** collects a **Window Stack** from **Window Candidates**, creates and manages a **Navigation Session**, and dispatches visual updates
- An **Overlay** (tooltip/list/tile) + optional **Peek** (border/snapshot at window position) present the current selection from a **Navigation Session**
- **Dock Hover** produces a **Trigger Context** by merging a **Dock Trigger** configuration with the hovered app's bundle ID from the **Dock Observer**, processed through the shared **Dock Action Handler**
- **Keyboard Navigation** can step through or activate a **Navigation Session** across Hotkey, Dock, and Desktop triggers
- **Desktop Switch** bypasses the Navigation Session entirely — the **Space Switcher** produces synthesized dock swipe events.

## Example dialogue

> **Dev:** "When a **Hotkey Trigger** is held and the user scrolls, does the **Event Router** create a **Navigation Session**?"
> **Domain expert:** "No — the router emits a scroll action. The **Navigation Coordinator** collects **Window Candidates** into a **Window Stack** and starts a **Navigation Session** if there are at least two candidates."

> **Dev:** "For **Dock Hover**, where does the **Trigger Context** come from?"
> **Domain expert:** "It's produced directly from the **Dock Trigger** configuration merged with the hovered app's bundle ID. An optional matched **Hotkey Trigger** can provide additional overlay and navigation settings — if none matches the modifier, dock defaults apply."

> **Dev:** "What's the difference between **Overlay** and **Peek**?"
> **Domain expert:** "The **Overlay** is the selection list near the cursor — tooltip, list, or tiles. The **Peek** is a separate window at the actual window's position on screen, showing a snapshot to make it feel like the window is already on top. They're shown simultaneously during a session."

> **Dev:** "Can keyboard navigation work without holding the scroll modifier?"
> **Domain expert:** "Yes — that's **keyboard-only activation**. If you press a keyboard nav binding when no trigger is active, the **Event Router** finds the **Hotkey Trigger** that owns that binding and activates it. You can scroll or step from there."

> **Dev:** "What happens when I release the trigger modifier?"
> **Domain expert:** "The **Trigger Release Behavior** kicks in. If there's an active **Navigation Session**, it confirms the selection (raises the window). If no session, the overlay dismisses."

## Flagged ambiguities

- "trigger" was used loosely to mean both the key-combination configuration and the active session — resolved: **Trigger** is the configuration; **Trigger Context** is the resolved runtime state.
- "hotkey" was used interchangeably with trigger — resolved: **Trigger** (or specifically **Hotkey Trigger**) is the domain concept; "hotkey" refers to the raw key flags (`HotkeyConfiguration`).
- "peek" conflated border highlight and snapshot — clarified: **Peek** is always positioned at the window's screen bounds; the **Peek Presentation Policy** decides border-only vs snapshot per selection.
- "event router" described as pure — corrected: the `EventClassifier` is now stateless; mutable session state (active trigger, dock session flag, scroll accumulator) is separated into `RouterSessionState`.
- "overlay" used to mean only the selection list — broadened to include the three presentation modes (tooltip, list, tile) plus the separate desktop switch overlay, distinguished from **Peek** which is window-positioned.