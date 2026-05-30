import CoreGraphics

@MainActor
public protocol WindowStackProviding {
	func candidates(matching query: WindowStackQuery) -> [WindowCandidate]
}

@MainActor
public protocol OverlayPresenting {
	func showStack(
		candidates: [WindowCandidate], selected: WindowCandidate?, at cursor: CGPoint, scope: TriggerScope,
		transitionDirection: Int, preserveVisibleFrame: Bool, display: OverlayDisplayConfig)
	func showDesktopSwitch(title: String, subtitle: String, selectedIndex: Int, totalCount: Int, at cursor: CGPoint, display: OverlayDisplayConfig)
	func repositionOverlay(to cursor: CGPoint)
	func hide()
}

@MainActor
public protocol WindowRaising {
	func raise(candidate: WindowCandidate)
}
