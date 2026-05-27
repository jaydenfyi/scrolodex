import ScrolodexCore

public struct RuntimeConfiguration: Sendable, Equatable {
	public let globallyDisabled: Bool
	public let scrollThreshold: Double
	public let appearance: RuntimeAppearanceSettings
	public let triggers: [TriggerHotkey]
	public let gestureConfigs: [GestureTriggerConfig]
	public let desktopTriggers: [DesktopSwitchTrigger]
	public let dockHoverConfigurations: [DockHoverConfiguration]

	public init(
		globallyDisabled: Bool,
		scrollThreshold: Double,
		appearance: RuntimeAppearanceSettings,
		triggers: [TriggerHotkey],
		gestureConfigs: [GestureTriggerConfig],
		desktopTriggers: [DesktopSwitchTrigger],
		dockHoverConfigurations: [DockHoverConfiguration]
	) {
		self.globallyDisabled = globallyDisabled
		self.scrollThreshold = scrollThreshold
		self.appearance = appearance
		self.triggers = triggers
		self.gestureConfigs = gestureConfigs
		self.desktopTriggers = desktopTriggers
		self.dockHoverConfigurations = dockHoverConfigurations
	}
}
