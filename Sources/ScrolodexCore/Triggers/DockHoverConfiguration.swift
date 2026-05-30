import CoreGraphics

public struct DockHoverConfiguration: Equatable, Sendable {
	public let enabled: Bool
	public let modifierFlags: UInt64
	public let monitorScope: MonitorScope
	public let overlayMode: OverlayPresentationMode
	public let showOnPress: Bool
	public let invertDirection: Bool
	public let animate: Bool
	public let wrapAround: Bool
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let theme: OverlayTheme
	public let keyboardNavigation: KeyboardNavigationBinding

	public init(
		enabled: Bool = false,
		modifierFlags: UInt64 = CGEventFlags.maskAlternate.rawValue,
		monitorScope: MonitorScope = SettingDefaults.monitorScope,
		overlayMode: OverlayPresentationMode = SettingDefaults.overlayMode,
		showOnPress: Bool = SettingDefaults.showOnPress,
		invertDirection: Bool = SettingDefaults.invertDirection,
		animate: Bool = SettingDefaults.animate,
		wrapAround: Bool = SettingDefaults.wrapAround,
		peekEnabled: Bool = SettingDefaults.peekEnabled,
		peekOpacity: Double = SettingDefaults.peekOpacity,
		theme: OverlayTheme = SettingDefaults.theme,
		keyboardNavigation: KeyboardNavigationBinding = KeyboardNavigationBinding()
	) {
		self.enabled = enabled
		self.modifierFlags = modifierFlags
		self.monitorScope = monitorScope
		self.overlayMode = overlayMode
		self.showOnPress = showOnPress
		self.invertDirection = invertDirection
		self.animate = animate
		self.wrapAround = wrapAround
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
		self.keyboardNavigation = keyboardNavigation
	}

	public func modifierMatches(_ flags: CGEventFlags) -> Bool {
		flags.contains(CGEventFlags(rawValue: modifierFlags))
	}

	public var allKeyboardBindings: [KeyboardHotkeyConfiguration] {
		keyboardNavigation.allBindings
	}
}
