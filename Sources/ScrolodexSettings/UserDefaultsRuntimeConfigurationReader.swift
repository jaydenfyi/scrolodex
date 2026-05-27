import CoreGraphics
import Foundation
import ScrolodexCore

public struct UserDefaultsRuntimeConfigurationReader: Sendable {
	public static func read(from defaults: UserDefaults = .standard) -> RuntimeConfiguration {
		let globallyDisabled = defaults.object(forKey: SettingKey.disabled) as? Bool ?? false
		let sensitivity = defaults.double(forKey: SettingKey.scrollSensitivity)
		let scrollThreshold = ScrollSensitivity.invert(sensitivity > 0 ? sensitivity : SettingDefaults.scrollSensitivity)
		let appearance = RuntimeAppearanceSettings.read(from: defaults)
		let triggers = buildTriggers(defaults: defaults, appearance: appearance)
		let gestureConfigs = buildGestureConfigs(defaults: defaults, appearance: appearance)
		let desktopTriggers = buildDesktopTriggers(defaults: defaults)
		let dockHoverConfigs = buildDockHoverConfigurations(defaults: defaults, appearance: appearance)

		return RuntimeConfiguration(
			globallyDisabled: globallyDisabled,
			scrollThreshold: scrollThreshold,
			appearance: appearance,
			triggers: triggers,
			gestureConfigs: gestureConfigs,
			desktopTriggers: desktopTriggers,
			dockHoverConfigurations: dockHoverConfigs
		)
	}

	private static func buildTriggers(defaults: UserDefaults, appearance: RuntimeAppearanceSettings) -> [TriggerHotkey] {
		TriggerSettingCatalog.windowEntries.compactMap { entry in
			let enabled = defaults.bool(forKey: "\(entry.prefix).enabled")
			guard enabled else { return nil }

			let rawFlags = defaults.double(forKey: "\(entry.prefix).flags")
			let resolvedRaw = rawFlags > 0 ? UInt64(rawFlags) : entry.defaultModifierFlags
			let flags = CGEventFlags(rawValue: resolvedRaw)

			let overlayRaw =
				defaults.string(forKey: "\(entry.prefix).overlay")
				?? SettingDefaults.overlayMode.rawValue
			let overlayMode = OverlayPresentationMode(rawValue: overlayRaw) ?? SettingDefaults.overlayMode
			let monitorScopeRaw =
				defaults.string(forKey: "\(entry.prefix).monitorScope")
				?? SettingDefaults.monitorScope.rawValue
			let monitorScope = MonitorScope(rawValue: monitorScopeRaw) ?? SettingDefaults.monitorScope

			let keyboardNav = buildKeyboardNavigation(prefix: entry.prefix, defaults: defaults)

			let showOnPress = defaults.object(forKey: "\(entry.prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress
			let invertDirection = defaults.bool(forKey: "\(entry.prefix).invertDirection")

			return TriggerHotkey(
				configuration: entry.configuration,
				hotkey: HotkeyConfiguration(flags: flags),
				overlayMode: overlayMode,
				peekEnabled: appearance.peekEnabled,
				peekOpacity: appearance.peekOpacity,
				theme: appearance.theme,
				monitorScope: monitorScope,
				showOnPress: showOnPress,
				invertDirection: invertDirection,
				animate: appearance.animate,
				wrapAround: appearance.wrapAround,
				keyboardNavigation: keyboardNav
			)
		}
	}

	private static func buildGestureConfigs(defaults: UserDefaults, appearance: RuntimeAppearanceSettings) -> [GestureTriggerConfig] {
		TriggerSettingCatalog.windowEntries.compactMap { entry in
			let enabled = defaults.bool(forKey: "\(entry.prefix).enabled")
			guard enabled else { return nil }

			let rawFingerCount = defaults.integer(forKey: "\(entry.prefix).gesture")
			guard let fingerCount = TrackpadFingerCount(rawValue: rawFingerCount) else { return nil }

			let overlayRaw =
				defaults.string(forKey: "\(entry.prefix).overlay")
				?? OverlayPresentationMode.default.rawValue
			let overlayMode = OverlayPresentationMode(rawValue: overlayRaw) ?? .default
			let monitorScopeRaw =
				defaults.string(forKey: "\(entry.prefix).monitorScope")
				?? MonitorScope.currentMonitor.rawValue
			let monitorScope = MonitorScope(rawValue: monitorScopeRaw) ?? .currentMonitor
			let invertDirection = defaults.bool(forKey: "\(entry.prefix).invertDirection")

			return GestureTriggerConfig(
				fingerCount: fingerCount,
				scope: entry.configuration.scope,
				filter: entry.configuration.filter,
				overlayMode: overlayMode,
				peekEnabled: appearance.peekEnabled,
				peekOpacity: appearance.peekOpacity,
				theme: appearance.theme,
				monitorScope: monitorScope,
				invertDirection: invertDirection,
				animate: appearance.animate,
				wrapAround: appearance.wrapAround
			)
		}
	}

	private static func buildDesktopTriggers(defaults: UserDefaults) -> [DesktopSwitchTrigger] {
		let enabled = defaults.bool(forKey: SettingKey.DesktopSwitch.enabled)
		guard enabled else { return [] }

		let rawFlags =
			defaults.object(forKey: SettingKey.DesktopSwitch.flags) as? Double
			?? Double(HotkeyConfiguration.defaultDesktopSwitch.flags.rawValue)
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		guard !flags.isEmpty else { return [] }

		let invertDirection = defaults.bool(forKey: SettingKey.DesktopSwitch.invertDirection)
		let animateScroll = defaults.object(forKey: SettingKey.DesktopSwitch.animate) as? Bool ?? SettingDefaults.desktopSwitchAnimate
		let wrapAround = defaults.object(forKey: SettingKey.DesktopSwitch.wrapAround) as? Bool ?? SettingDefaults.desktopSwitchWrapAround
		let keyboardNav = buildDesktopKeyboardNavigation(defaults: defaults)

		return [
			DesktopSwitchTrigger(
				hotkey: HotkeyConfiguration(flags: flags),
				invertDirection: invertDirection,
				animateScroll: animateScroll,
				wrapAround: wrapAround,
				keyboardNavigation: keyboardNav
			)
		]
	}

	private static func buildDockHoverConfigurations(defaults: UserDefaults, appearance: RuntimeAppearanceSettings) -> [DockHoverConfiguration] {
		TriggerSettingCatalog.dockHoverEntries.map { entry in
			migrateDockHoverDefaults(from: "dockHover", to: entry.prefix, defaults: defaults)

			let enabled = defaults.bool(forKey: "\(entry.prefix).enabled")
			let rawFlags = defaults.double(forKey: "\(entry.prefix).flags")
			let modifierFlags = rawFlags > 0 ? UInt64(rawFlags) : CGEventFlags.maskAlternate.rawValue
			let monitorScopeRaw = defaults.string(forKey: "\(entry.prefix).monitorScope") ?? MonitorScope.allMonitors.rawValue
			let overlayRaw = defaults.string(forKey: "\(entry.prefix).overlay") ?? SettingDefaults.overlayMode.rawValue
			let kbNavEnabled = defaults.object(forKey: "\(entry.prefix).keyboardNav.enabled") as? Bool ?? false
			let kbForwardFlags = defaults.double(forKey: "\(entry.prefix).keyboardNav.forwardFlags")
			let kbForwardKeyCode = defaults.double(forKey: "\(entry.prefix).keyboardNav.forwardKeyCode")
			let kbBackwardFlags = defaults.double(forKey: "\(entry.prefix).keyboardNav.backwardFlags")
			let kbBackwardKeyCode = defaults.double(forKey: "\(entry.prefix).keyboardNav.backwardKeyCode")

			return DockHoverConfiguration(
				enabled: enabled,
				modifierFlags: modifierFlags,
				monitorScope: MonitorScope(rawValue: monitorScopeRaw) ?? .allMonitors,
				overlayMode: OverlayPresentationMode(rawValue: overlayRaw) ?? .default,
				showOnPress: defaults.object(forKey: "\(entry.prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress,
				invertDirection: defaults.object(forKey: "\(entry.prefix).invertDirection") as? Bool ?? SettingDefaults.invertDirection,
				animate: appearance.animate,
				wrapAround: appearance.wrapAround,
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
	}

	private static func buildKeyboardNavigation(prefix: String, defaults: UserDefaults) -> KeyboardNavigationBinding {
		let kbEnabled = defaults.bool(forKey: "\(prefix).keyboardNav.enabled")
		let forward = buildKeyBinding(prefix: prefix, direction: "forward", defaults: defaults)
		let backward = buildKeyBinding(prefix: prefix, direction: "backward", defaults: defaults)
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private static func buildKeyBinding(prefix: String, direction: String, defaults: UserDefaults) -> KeyboardHotkeyConfiguration? {
		let rawFlags = defaults.double(forKey: "\(prefix).keyboardNav.\(direction)Flags")
		let rawKeyCode = defaults.double(forKey: "\(prefix).keyboardNav.\(direction)KeyCode")
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		let keyCode = CGKeyCode(rawKeyCode)
		guard keyCode != 0 else { return nil }
		return KeyboardHotkeyConfiguration(flags: flags, keyCode: keyCode)
	}

	private static func buildDesktopKeyboardNavigation(defaults: UserDefaults) -> KeyboardNavigationBinding {
		let kbEnabled = defaults.bool(forKey: SettingKey.DesktopSwitch.keyboardNavEnabled)
		let forward = buildDesktopKeyBinding(direction: "forward", defaults: defaults)
		let backward = buildDesktopKeyBinding(direction: "backward", defaults: defaults)
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private static func buildDesktopKeyBinding(direction: String, defaults: UserDefaults) -> KeyboardHotkeyConfiguration? {
		let flagsKey =
			direction == "forward"
			? SettingKey.DesktopSwitch.keyboardNavForwardFlags
			: SettingKey.DesktopSwitch.keyboardNavBackwardFlags
		let keyCodeKey =
			direction == "forward"
			? SettingKey.DesktopSwitch.keyboardNavForwardKeyCode
			: SettingKey.DesktopSwitch.keyboardNavBackwardKeyCode
		let rawFlags = defaults.double(forKey: flagsKey)
		let rawKeyCode = defaults.double(forKey: keyCodeKey)
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		let keyCode = CGKeyCode(rawKeyCode)
		guard keyCode != 0 else { return nil }
		return KeyboardHotkeyConfiguration(flags: flags, keyCode: keyCode)
	}

	private static func migrateDockHoverDefaults(from old: String, to new: String, defaults: UserDefaults) {
		guard defaults.object(forKey: "\(new).flags") == nil,
			defaults.object(forKey: "\(old).modifierFlags") != nil
		else { return }

		let mapping: [(old: String, new: String)] = [
			("enabled", "enabled"),
			("modifierFlags", "flags"),
			("showOnPress", "showOnPress"),
		]
		for pair in mapping {
			if let val = defaults.object(forKey: "\(old).\(pair.old)") {
				defaults.set(val, forKey: "\(new).\(pair.new)")
			}
		}
	}
}
