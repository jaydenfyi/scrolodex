import CoreGraphics
import ScrolodexCore

public struct TriggerSettingCatalogEntry: Equatable, Sendable {
	public let prefix: String
	public let configuration: TriggerConfiguration
	public let defaultModifierFlags: UInt64

	public init(prefix: String, configuration: TriggerConfiguration, defaultModifierFlags: UInt64) {
		self.prefix = prefix
		self.configuration = configuration
		self.defaultModifierFlags = defaultModifierFlags
	}
}

public enum TriggerSettingCatalog {
	public static let windowEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "trigger.underCursor.allApps",
			configuration: TriggerConfiguration(scope: .underCursor, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue
		),
		TriggerSettingCatalogEntry(
			prefix: "trigger.currentScreen.allApps",
			configuration: TriggerConfiguration(scope: .currentScreen, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue
		),
	]

	public static let dockHoverEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "dockHover.allMonitors",
			configuration: TriggerConfiguration(scope: .dockHover, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskAlternate.rawValue
		),
	]
}
