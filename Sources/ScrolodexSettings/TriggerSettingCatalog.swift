import CoreGraphics
import ScrolodexCore

public struct TriggerSettingCatalogEntry: Equatable, Sendable {
	public let prefix: String
	public let configuration: TriggerConfiguration
	public let defaultModifierFlags: UInt64
	public let enabled: Bool
	public let keyboardNavDefaults: KeyboardNavDefaults?

	public struct KeyboardNavDefaults: Equatable, Sendable {
		public let enabled: Bool
		public let forwardFlags: Double
		public let forwardKeyCode: Double
		public let backwardFlags: Double
		public let backwardKeyCode: Double

		public init(enabled: Bool, forwardFlags: Double, forwardKeyCode: Double, backwardFlags: Double, backwardKeyCode: Double) {
			self.enabled = enabled
			self.forwardFlags = forwardFlags
			self.forwardKeyCode = forwardKeyCode
			self.backwardFlags = backwardFlags
			self.backwardKeyCode = backwardKeyCode
		}
	}

	public init(prefix: String, configuration: TriggerConfiguration, defaultModifierFlags: UInt64, enabled: Bool, keyboardNavDefaults: KeyboardNavDefaults? = nil) {
		self.prefix = prefix
		self.configuration = configuration
		self.defaultModifierFlags = defaultModifierFlags
		self.enabled = enabled
		self.keyboardNavDefaults = keyboardNavDefaults
	}
}

public enum TriggerSettingCatalog {
	public static let windowEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "trigger.underCursor.allApps",
			configuration: TriggerConfiguration(scope: .underCursor, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue,
			enabled: true,
			keyboardNavDefaults: .init(
				enabled: true,
				forwardFlags: 524288.0,
				forwardKeyCode: 50.0,
				backwardFlags: 655360.0,
				backwardKeyCode: 50.0
			)
		),
		TriggerSettingCatalogEntry(
			prefix: "trigger.currentScreen.allApps",
			configuration: TriggerConfiguration(scope: .currentScreen, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue,
			enabled: true,
			keyboardNavDefaults: .init(
				enabled: true,
				forwardFlags: 1572864.0,
				forwardKeyCode: 50.0,
				backwardFlags: 1703936.0,
				backwardKeyCode: 50.0
			)
		),
	]

	public static let dockHoverEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "dockHover.allMonitors",
			configuration: TriggerConfiguration(scope: .dockHover, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskAlternate.rawValue,
			enabled: true,
			keyboardNavDefaults: .init(
				enabled: true,
				forwardFlags: 524288.0,
				forwardKeyCode: 50.0,
				backwardFlags: 655360.0,
				backwardKeyCode: 50.0
			)
		),
	]

	public static let featureFlaggedEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "trigger.underCursor.sameApp",
			configuration: TriggerConfiguration(scope: .underCursor, filter: .sameApp),
			defaultModifierFlags: 0,
			enabled: false
		),
		TriggerSettingCatalogEntry(
			prefix: "trigger.currentScreen.sameApp",
			configuration: TriggerConfiguration(scope: .currentScreen, filter: .sameApp),
			defaultModifierFlags: 0,
			enabled: false
		),
		TriggerSettingCatalogEntry(
			prefix: "dockHover.currentMonitor",
			configuration: TriggerConfiguration(scope: .dockHover, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskAlternate.rawValue,
			enabled: false
		),
	]

	public static let desktopEntries: [TriggerSettingCatalogEntry] = [
		TriggerSettingCatalogEntry(
			prefix: "desktopSwitch",
			configuration: TriggerConfiguration(scope: .underCursor, filter: .allApps),
			defaultModifierFlags: CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskShift.rawValue,
			enabled: SettingDefaults.desktopSwitchEnabled,
			keyboardNavDefaults: .init(
				enabled: SettingDefaults.desktopSwitchKeyboardNavEnabled,
				forwardFlags: 0,
				forwardKeyCode: 0,
				backwardFlags: 0,
				backwardKeyCode: 0
			)
		),
	]
}
