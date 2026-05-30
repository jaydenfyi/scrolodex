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
		defaults.register(defaults: [
			// Triggers
			"trigger.underCursor.allApps.enabled": true,
			"trigger.underCursor.allApps.keyboardNav.enabled": true,
			"trigger.underCursor.allApps.keyboardNav.forwardFlags": 524288.0,
			"trigger.underCursor.allApps.keyboardNav.forwardKeyCode": 50.0,
			"trigger.underCursor.allApps.keyboardNav.backwardFlags": 655360.0,
			"trigger.underCursor.allApps.keyboardNav.backwardKeyCode": 50.0,

			"trigger.currentScreen.allApps.enabled": true,
			"trigger.currentScreen.allApps.keyboardNav.enabled": true,
			"trigger.currentScreen.allApps.keyboardNav.forwardFlags": 1572864.0,
			"trigger.currentScreen.allApps.keyboardNav.forwardKeyCode": 50.0,
			"trigger.currentScreen.allApps.keyboardNav.backwardFlags": 1703936.0,
			"trigger.currentScreen.allApps.keyboardNav.backwardKeyCode": 50.0,

			"trigger.underCursor.sameApp.enabled": false,
			"trigger.currentScreen.sameApp.enabled": false,

			// Dock
			"dockHover.currentMonitor.enabled": false,
			"dockHover.allMonitors.enabled": true,
			"dockHover.allMonitors.keyboardNav.enabled": true,
			"dockHover.allMonitors.keyboardNav.forwardFlags": 524288.0,
			"dockHover.allMonitors.keyboardNav.forwardKeyCode": 50.0,
			"dockHover.allMonitors.keyboardNav.backwardFlags": 655360.0,
			"dockHover.allMonitors.keyboardNav.backwardKeyCode": 50.0,

			// Global visual & behavior
			scrollSensitivity: SettingDefaults.scrollSensitivity,
			theme: SettingDefaults.theme.rawValue,
			animate: SettingDefaults.animate,
			wrapAround: SettingDefaults.wrapAround,
			peekEnabled: SettingDefaults.peekEnabled,
			peekOpacity: SettingDefaults.peekOpacity,

			// Desktop switch
			"desktopSwitch.enabled": SettingDefaults.desktopSwitchEnabled,
			"desktopSwitch.animate": SettingDefaults.desktopSwitchAnimate,
			"desktopSwitch.wrapAround": SettingDefaults.desktopSwitchWrapAround,
			"desktopSwitch.keyboardNav.enabled": SettingDefaults.desktopSwitchKeyboardNavEnabled,
		])
	}
}
