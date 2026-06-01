import Foundation
import ScrolodexCore

public enum SettingKey {
	public static let disabled = "disabled"
	public static let scrollSensitivity = "scrollSensitivity"
	public static let theme = "theme"
	public static let animate = "animate"
	public static let wrapAround = "wrapAround"
	public static let peekEnabled = "peek.enabled"
	public static let peekOpacity = "peek.opacity"

	public static func registerDefaults(in defaults: UserDefaults = .standard) {
		var registrations: [String: Any] = [:]

		for entry in TriggerSettingCatalog.windowEntries + TriggerSettingCatalog.dockHoverEntries
			+ TriggerSettingCatalog.desktopEntries + TriggerSettingCatalog.featureFlaggedEntries
		{
			registrations["\(entry.prefix).enabled"] = entry.enabled
			if let kb = entry.keyboardNavDefaults {
				registrations["\(entry.prefix).keyboardNav.enabled"] = kb.enabled
				registrations["\(entry.prefix).keyboardNav.forwardFlags"] = kb.forwardFlags
				registrations["\(entry.prefix).keyboardNav.forwardKeyCode"] = kb.forwardKeyCode
				registrations["\(entry.prefix).keyboardNav.backwardFlags"] = kb.backwardFlags
				registrations["\(entry.prefix).keyboardNav.backwardKeyCode"] = kb.backwardKeyCode
			}
		}

		for entry in TriggerSettingCatalog.windowEntries {
			registrations["\(entry.prefix).gestureDirection"] = GestureSwipeDirection.vertical.rawValue
		}

		registrations["desktopSwitch.animate"] = SettingDefaults.desktopSwitchAnimate
		registrations["desktopSwitch.wrapAround"] = SettingDefaults.desktopSwitchWrapAround

		registrations[scrollSensitivity] = SettingDefaults.scrollSensitivity
		registrations[theme] = SettingDefaults.theme.rawValue
		registrations[animate] = SettingDefaults.animate
		registrations[wrapAround] = SettingDefaults.wrapAround
		registrations[peekEnabled] = SettingDefaults.peekEnabled
		registrations[peekOpacity] = SettingDefaults.peekOpacity

		defaults.register(defaults: registrations)
	}
}
