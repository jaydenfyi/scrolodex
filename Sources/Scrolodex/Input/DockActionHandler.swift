import Foundation
import ScrolodexCore

@MainActor
final class DockActionHandler: DockActionHandling {
	private let coordinator: NavigationCoordinator
	private let scrollThreshold: Double
	private let peekEnabled: Bool
	private let peekOpacity: Double
	private let theme: OverlayTheme

	init(
		coordinator: NavigationCoordinator,
		scrollThreshold: Double,
		peekEnabled: Bool,
		peekOpacity: Double,
		theme: OverlayTheme
	) {
		self.coordinator = coordinator
		self.scrollThreshold = scrollThreshold
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
	}

	func handle(dockAction: DockAction) {
		switch dockAction {
		case .activate(let config, let bundleID):
			let context = buildContext(
				dockConfig: config, peekOpacity: peekOpacity, theme: theme,
				bundleID: bundleID)
			coordinator.activate(context)

		case .scroll(let delta, let config, let anchor, let bundleID):
			let context = buildContext(
				dockConfig: config, peekOpacity: peekOpacity, theme: theme,
				bundleID: bundleID)
			coordinator.activate(context)
			coordinator.handleScroll(delta: delta, cursor: anchor)

		case .preview(let config, let anchor, let bundleID):
			let context = buildContext(
				dockConfig: config, peekOpacity: peekOpacity, theme: theme,
				bundleID: bundleID)
			coordinator.previewTrigger(context: context, cursor: anchor, hotkeyName: "Dock Hover")

		case .keyboardNavigate(let direction, let config, let anchor, let bundleID):
			let context = buildContext(
				dockConfig: config, peekOpacity: peekOpacity, theme: theme,
				bundleID: bundleID)
			coordinator.activate(context)
			coordinator.handleKeyboardNavigation(direction: direction, cursor: anchor)

		case .released:
			coordinator.handleTriggerRelease()
		}
	}

	// MARK: - Private

	private func buildContext(
		dockConfig: DockHoverConfiguration,
		peekOpacity: Double,
		theme: OverlayTheme,
		bundleID: String
	) -> TriggerContext {
		TriggerContext.from(
			dockConfig: dockConfig,
			peekEnabled: peekEnabled,
			peekOpacity: peekOpacity,
			theme: theme,
			bundleID: bundleID,
			scrollThreshold: scrollThreshold
		)
	}
}
