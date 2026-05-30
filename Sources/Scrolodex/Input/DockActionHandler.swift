import Foundation
import ScrolodexCore

@MainActor
final class DockActionHandler: DockActionHandling {
	private let coordinator: NavigationCoordinator
	private let scrollThreshold: Double

	init(
		coordinator: NavigationCoordinator,
		scrollThreshold: Double
	) {
		self.coordinator = coordinator
		self.scrollThreshold = scrollThreshold
	}

	func handle(dockAction: DockAction) {
		switch dockAction {
		case .activate(let config, let bundleID):
			let context = TriggerContext.from(
				dockConfig: config, bundleID: bundleID, scrollThreshold: scrollThreshold)
			coordinator.activate(context)

		case .scroll(let delta, let config, let anchor, let bundleID):
			let context = TriggerContext.from(
				dockConfig: config, bundleID: bundleID, scrollThreshold: scrollThreshold)
			coordinator.activate(context)
			coordinator.handleScroll(delta: delta, cursor: anchor)

		case .preview(let config, let anchor, let bundleID):
			let context = TriggerContext.from(
				dockConfig: config, bundleID: bundleID, scrollThreshold: scrollThreshold)
			coordinator.previewTrigger(context: context, cursor: anchor, hotkeyName: "Dock Hover")

		case .keyboardNavigate(let direction, let config, let anchor, let bundleID):
			let context = TriggerContext.from(
				dockConfig: config, bundleID: bundleID, scrollThreshold: scrollThreshold)
			coordinator.activate(context)
			coordinator.handleKeyboardNavigation(direction: direction, cursor: anchor)

		case .released:
			coordinator.handleTriggerRelease()
		}
	}
}
