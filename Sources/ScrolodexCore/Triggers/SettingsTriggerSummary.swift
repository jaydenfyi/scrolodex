import CoreGraphics

public struct SettingsTriggerSummary: Equatable, Sendable {
	public let enabled: Bool
	public let flags: UInt64
	public let overlayMode: OverlayPresentationMode
	public let monitorScope: MonitorScope?
	public let keyboardNavigationEnabled: Bool

	public init(
		enabled: Bool,
		flags: UInt64,
		overlayMode: OverlayPresentationMode,
		monitorScope: MonitorScope?,
		keyboardNavigationEnabled: Bool
	) {
		self.enabled = enabled
		self.flags = flags
		self.overlayMode = overlayMode
		self.monitorScope = monitorScope
		self.keyboardNavigationEnabled = keyboardNavigationEnabled
	}

	public var chips: [String] {
		guard enabled else { return ["Disabled"] }

		var values = [HotkeyConfiguration(rawValue: flags).displayName]
		values.append(overlayMode.displayName)
		if let monitorScope { values.append(monitorScope.displayName) }
		if keyboardNavigationEnabled { values.append("Keyboard") }
		return values
	}

	public var compactChips: [String] {
		guard enabled else { return ["Disabled"] }

		var values = [HotkeyConfiguration(rawValue: flags).compactDisplayName]
		values.append(overlayMode.displayName)
		if let monitorScope { values.append(monitorScope == .allMonitors ? "All" : "Current") }
		if keyboardNavigationEnabled { values.append("Keys") }
		return values
	}
}
