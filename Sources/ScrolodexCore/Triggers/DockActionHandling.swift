import CoreGraphics

/// Processes dock hover actions. Concrete implementations read global
/// defaults (peekOpacity, theme) to construct TriggerContext and bridge
/// to NavigationCoordinator.
@MainActor
public protocol DockActionHandling {
	func handle(dockAction: DockAction)
}
