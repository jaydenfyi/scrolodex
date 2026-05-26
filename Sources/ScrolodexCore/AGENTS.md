# ScrolodexCore

Core domain library — all navigation and window-switching logic. Pure model types + stateful pipelines. No AppKit. No persistence.

## STRUCTURE

```
ScrolodexCore/
├── EventRouter/            # Input → action classification
│   ├── EventClassifier.swift       # Stateless Sendable struct, classify(event:dockHover:state:)
│   ├── RouterSessionState.swift    # Mutable session state (inout param) — activeTrigger, dockSessionActive, scrollAccumulator
│   ├── RouterTypes.swift           # RouterEvent, RouterDirective, RouterAction, WindowAction, DesktopAction, DockAction, SystemAction
│   └── EventTapPolicy.swift        # Maps event type + triggerHeld → semantic action
├── Navigation/             # Session lifecycle
│   ├── NavigationCoordinator.swift # @MainActor orchestrator — activate, scroll, confirm, cancel
│   ├── NavigationProtocols.swift   # WindowStackProviding, OverlayPresenting, WindowRaising (the 3 seams to app layer)
│   ├── NavigationSession.swift     # Value-type selection state machine — scrollAccum, wrap, step
│   ├── OverlayAnchorSession.swift  # Persistent anchor point for Dock Hover overlay positioning
│   └── TriggerReleaseBehavior.swift # Confirm vs dismiss on trigger release
├── Triggers/               # Trigger configuration system
│   ├── TriggerModels.swift         # TriggerHotkey, DesktopSwitchTrigger, GestureTriggerConfig
│   ├── TriggerConfiguration.swift  # TriggerScope, TriggerFilter, MonitorScope enums + TriggerConfiguration struct
│   ├── TriggerContext.swift         # Resolved runtime config — factory from Trigger or DockHoverConfiguration
│   ├── DockActionHandling.swift     # @MainActor protocol for DockAction processing
│   ├── DockHoverConfiguration.swift # Dock trigger config with UserDefaults deserialization + migration
│   ├── HotkeyConfiguration.swift    # Modifier key matching
│   ├── KeyboardHotkeyConfiguration.swift
│   ├── KeyboardNavigationBinding.swift
│   └── SettingsTriggerSummary.swift
├── Overlay/                # Visual presentation models
│   ├── OverlayTheme.swift           # Theme enum + color model
│   ├── OverlayPresentationMode.swift # none, tooltip, list, tile
│   ├── OverlayPlacement.swift       # Positioning geometry
│   ├── OverlayDisplayConfig.swift   # Presentation config derived from TriggerContext
│   ├── OverlayTransition.swift      # Show/hide/scroll transition models
│   ├── CursorTooltipPlacement.swift # Tooltip positioning math
│   ├── PeekMode.swift               # Border vs snapshot peek modes
│   ├── PeekPresentationPolicy.swift # Decides border-only vs snapshot per selection
│   └── WindowStackOverlayModel.swift # View model for overlay content
├── WindowQuery/            # Window collection + filtering
│   ├── WindowCandidate.swift        # Value type: CG window ID, PID, owner, title, bounds, layer, alpha
│   ├── WindowStackFilter.swift      # Static filtering: scope, filter, monitor scope
│   ├── WindowStackQuery.swift       # Query parameters struct
│   ├── CGWindowDictionaryParser.swift # CGWindowList dictionaries → WindowCandidate
│   └── AXWindowAccessor.swift       # Accessibility API helper
├── Desktop/                # Space switching
│   └── SpaceSwitcher.swift          # SkyLight private APIs + synthesized dock swipe events
├── SettingDefaults.swift   # Canonical fallback values for all settings
├── Log.swift               # NSLog wrapper with debug toggle
└── MenuBarIconConfiguration.swift
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add a trigger type | `Triggers/TriggerModels.swift` → `EventRouter/EventClassifier.swift` → `EventRouter/RouterTypes.swift` | New enum case + config struct + routing logic |
| Change scroll/navigation behavior | `Navigation/NavigationSession.swift` | Threshold, wrap, keyboard step |
| Change event classification | `EventRouter/EventClassifier.swift` | Stateless — all routing logic here |
| Add overlay presentation mode | `Overlay/OverlayPresentationMode.swift` → `Overlay/OverlayDisplayConfig.swift` | Enum case + config derivation |
| Change window filtering | `WindowQuery/WindowStackFilter.swift` | Scope/filter/monitor predicates |
| Add Space switching feature | `Desktop/SpaceSwitcher.swift` | Private API boundary |
| Change setting defaults | `SettingDefaults.swift` | Single source of truth for all fallbacks |

## DEPENDENCY FLOW

```
EventRouter → Triggers → Navigation → Overlay
                │            │            │
                └────────────┴────────────┘
                          WindowQuery
```

No circular dependencies. `SettingDefaults` (root) references types from `Overlay/` and `Triggers/` — acceptable for a constants file. `MonitorScope` (defined in `Triggers/`) is the most widely cross-referenced type — used in `WindowQuery/`, `Overlay/`, and `SettingDefaults`.

## CONVENTIONS

- **All types `public`** — library target consumed by app
- **`@MainActor` limited to `NavigationCoordinator`** and protocols in `NavigationProtocols.swift`
- **`EventClassifier` is stateless** — `Sendable` struct, state passed as `inout RouterSessionState`
- **`RouterSessionState` is a value type** — caller owns mutation, passed as `inout`
- **`Sendable` conformance** on all value types; `@unchecked Sendable` only where documented (main run loop serialization)

## ANTI-PATTERNS

- **Never `import AppKit`** — this is a pure domain library
- **Never add UserDefaults/persistence** — storage is the app layer's concern
- **Never put UI logic in models** — `OverlayTheme` is data, not views
- **Never reference concrete app types** — use the 3 protocols in `NavigationProtocols.swift`
