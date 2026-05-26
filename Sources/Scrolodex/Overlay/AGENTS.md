# Overlay

Selection UI subsystem — visual presentation of the Window Stack during navigation sessions. Pure AppKit (NSView, CALayer, custom drawing). No SwiftUI.

## WHERE TO LOOK

| Task | File | Notes |
|------|------|-------|
| Adding overlay mode | `OverlayController.swift` + `OverlayView.swift` | Controller manages NSPanel lifecycle; View does layout |
| Modifying peek behavior | `PeekBadgeView.swift`, `PeekSnapshotView.swift` | Border highlight + window snapshot at position |
| Tile layout | `TileOverlayView.swift` | Horizontal scrolling tiles with thumbnails |
| Animation | `OverlayAnimation.swift` | Scroll transitions, show/hide, peek fade |
| Drawing / selection indicator | `OverlayDrawing.swift` | Custom NSView drawing for selection |
| Theme resolution | `OverlayTheme+Resolved.swift` | Theme model → resolved NSColor values |
| Color token mapping | `NSColor+TokenColor.swift` | `OverlayTheme.ColorToken` → `NSColor` |
| Row view model | `OverlayRowViewModel.swift` | Per-row state (selected, icon, title) |

## CONVENTIONS

- **AppKit views only** — NSView, CALayer, custom drawing. No SwiftUI anywhere in this directory
- **Positioning**: Overlay at cursor/Dock icon; Peek at the selected window's screen bounds
- **Theme-driven colors** — always go through `OverlayTheme+Resolved.swift` + `NSColor+TokenColor.swift`, never hardcoded
- **OverlayController owns lifecycle** — show/hide/reposition/update; delegates content rendering to view classes
- **Models come from coordinator** — `WindowCandidate`, `OverlayTheme`, `OverlayDisplayConfig` passed in via method calls

## ANTI-PATTERNS

- **No business logic in views** — navigation state comes from `NavigationCoordinator` via update calls
- **No hardcoded colors** — always through `OverlayTheme`
- **No direct ScrolodexCore type imports in view files** — use models passed by the controller
