import Foundation
import ScrolodexCore

enum SettingKey {
	static let disabled = "disabled"
	static let scrollSensitivity = "scrollSensitivity"
	static let theme = "theme"
	static let animate = "animate"
	static let wrapAround = "wrapAround"
	static let peekEnabled = "peek.enabled"
	static let peekOpacity = "peek.opacity"

	enum DesktopSwitch {
		static let enabled = "desktopSwitch.enabled"
		static let flags = "desktopSwitch.flags"
		static let invertDirection = "desktopSwitch.invertDirection"
		static let animate = "desktopSwitch.animate"
		static let wrapAround = "desktopSwitch.wrapAround"
		static let keyboardNavEnabled = "desktopSwitch.keyboardNav.enabled"
		static let keyboardNavForwardFlags = "desktopSwitch.keyboardNav.forwardFlags"
		static let keyboardNavForwardKeyCode = "desktopSwitch.keyboardNav.forwardKeyCode"
		static let keyboardNavBackwardFlags = "desktopSwitch.keyboardNav.backwardFlags"
		static let keyboardNavBackwardKeyCode = "desktopSwitch.keyboardNav.backwardKeyCode"
	}

	/// Register all canonical default values with UserDefaults.
	/// Call once at app launch.  Consumers can then read with plain typed
	/// accessors (`bool(forKey:)`, `double(forKey:)`, `string(forKey:)`)
	/// without `??` fallbacks — the registration domain handles it.
	static func registerDefaults() {
		UserDefaults.standard.register(defaults: [
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
			DesktopSwitch.enabled: SettingDefaults.desktopSwitchEnabled,
			DesktopSwitch.animate: SettingDefaults.desktopSwitchAnimate,
			DesktopSwitch.wrapAround: SettingDefaults.desktopSwitchWrapAround,
			DesktopSwitch.keyboardNavEnabled: SettingDefaults.desktopSwitchKeyboardNavEnabled,
		])
	}
}
