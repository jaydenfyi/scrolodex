import Foundation

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
}
