import CoreGraphics
import Foundation

public struct DockHoverConfiguration: Equatable, Sendable {
	public let enabled: Bool
	public let modifierFlags: UInt64
	public let monitorScope: MonitorScope
	public let overlayMode: OverlayPresentationMode
	public let showPreviewOnHover: Bool
	public let showOnPress: Bool
	public let invertDirection: Bool
	public let animate: Bool
	public let wrapAround: Bool
	public let keyboardNavigation: KeyboardNavigationBinding

	public init(
		enabled: Bool = false,
		modifierFlags: UInt64 = CGEventFlags.maskAlternate.rawValue,
		monitorScope: MonitorScope = SettingDefaults.monitorScope,
		overlayMode: OverlayPresentationMode = SettingDefaults.overlayMode,
		showPreviewOnHover: Bool = SettingDefaults.showPreviewOnHover,
		showOnPress: Bool = SettingDefaults.showOnPress,
		invertDirection: Bool = SettingDefaults.invertDirection,
		animate: Bool = SettingDefaults.animate,
		wrapAround: Bool = SettingDefaults.wrapAround,
		keyboardNavigation: KeyboardNavigationBinding = KeyboardNavigationBinding()
	) {
		self.enabled = enabled
		self.modifierFlags = modifierFlags
		self.monitorScope = monitorScope
		self.overlayMode = overlayMode
		self.showPreviewOnHover = showPreviewOnHover
		self.showOnPress = showOnPress
		self.invertDirection = invertDirection
		self.animate = animate
		self.wrapAround = wrapAround
		self.keyboardNavigation = keyboardNavigation
	}

	public static func fromUserDefaults(
		defaults: UserDefaults = .standard,
		prefix: String = "dockHover",
		defaultMonitorScope: MonitorScope = .currentMonitor,
		globalAnimate: Bool = true,
		globalWrapAround: Bool = true,
		migrationPrefix: String? = nil
	) -> DockHoverConfiguration {
		if let migration = migrationPrefix {
			migrateDefaults(from: migration, to: prefix, defaults: defaults)
		}
		let enabled = defaults.bool(forKey: "\(prefix).enabled")
		let rawFlags = defaults.double(forKey: "\(prefix).flags")
		let modifierFlags = rawFlags > 0 ? UInt64(rawFlags) : CGEventFlags.maskAlternate.rawValue
		let monitorScopeRaw = defaults.string(forKey: "\(prefix).monitorScope") ?? defaultMonitorScope.rawValue
		let overlayRaw = defaults.string(forKey: "\(prefix).overlay") ?? SettingDefaults.overlayMode.rawValue
		let kbNavEnabled = defaults.object(forKey: "\(prefix).keyboardNav.enabled") as? Bool ?? false
		let kbForwardFlags = defaults.double(forKey: "\(prefix).keyboardNav.forwardFlags")
		let kbForwardKeyCode = defaults.double(forKey: "\(prefix).keyboardNav.forwardKeyCode")
		let kbBackwardFlags = defaults.double(forKey: "\(prefix).keyboardNav.backwardFlags")
		let kbBackwardKeyCode = defaults.double(forKey: "\(prefix).keyboardNav.backwardKeyCode")
		return DockHoverConfiguration(
			enabled: enabled,
			modifierFlags: modifierFlags,
			monitorScope: MonitorScope(rawValue: monitorScopeRaw) ?? defaultMonitorScope,
			overlayMode: OverlayPresentationMode(rawValue: overlayRaw) ?? .default,
			showPreviewOnHover: defaults.object(forKey: "\(prefix).showPreviewOnHover") as? Bool ?? SettingDefaults.showPreviewOnHover,
			showOnPress: defaults.object(forKey: "\(prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress,
			invertDirection: defaults.object(forKey: "\(prefix).invertDirection") as? Bool ?? SettingDefaults.invertDirection,
			animate: globalAnimate,
			wrapAround: globalWrapAround,
			keyboardNavigation: KeyboardNavigationBinding(
				enabled: kbNavEnabled,
				forward: kbForwardFlags > 0
					? KeyboardHotkeyConfiguration(
						flags: CGEventFlags(rawValue: UInt64(kbForwardFlags)),
						keyCode: CGKeyCode(kbForwardKeyCode))
					: nil,
				backward: kbBackwardFlags > 0
					? KeyboardHotkeyConfiguration(
						flags: CGEventFlags(rawValue: UInt64(kbBackwardFlags)),
						keyCode: CGKeyCode(kbBackwardKeyCode))
					: nil
			)
		)
	}

	public func modifierMatches(_ flags: CGEventFlags) -> Bool {
		flags.contains(CGEventFlags(rawValue: modifierFlags))
	}

	public var allKeyboardBindings: [KeyboardHotkeyConfiguration] {
		keyboardNavigation.allBindings
	}

	private static func migrateDefaults(from old: String, to new: String, defaults: UserDefaults) {
		guard defaults.object(forKey: "\(new).flags") == nil,
			defaults.object(forKey: "\(old).modifierFlags") != nil
		else { return }

		let mapping: [(old: String, new: String)] = [
			("enabled", "enabled"),
			("modifierFlags", "flags"),
			("showPreviewOnHover", "showPreviewOnHover"),
			("showOnPress", "showOnPress"),
		]
		for pair in mapping {
			if let val = defaults.object(forKey: "\(old).\(pair.old)") {
				defaults.set(val, forKey: "\(new).\(pair.new)")
			}
		}
	}
}
