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
			guard defaults.bool(forKey: "\(entry.prefix).enabled") else { return nil }

			let rawFlags = defaults.double(forKey: "\(entry.prefix).flags")
			let resolvedRaw = rawFlags > 0 ? UInt64(rawFlags) : entry.defaultModifierFlags
			let flags = CGEventFlags(rawValue: resolvedRaw)
			let settings = PerTriggerSettings.read(prefix: entry.prefix, defaults: defaults)
			let keyboardNav = buildKeyboardNavigation(prefix: entry.prefix, defaults: defaults)
			let showOnPress = defaults.object(forKey: "\(entry.prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress

			return TriggerHotkey(
				configuration: entry.configuration,
				hotkey: HotkeyConfiguration(flags: flags),
				overlayMode: settings.overlayMode,
				peekEnabled: appearance.peekEnabled,
				peekOpacity: appearance.peekOpacity,
				theme: appearance.theme,
				monitorScope: settings.monitorScope,
				showOnPress: showOnPress,
				invertDirection: settings.invertDirection,
				animate: appearance.animate,
				wrapAround: appearance.wrapAround,
				keyboardNavigation: keyboardNav
			)
		}
	}

	private static func buildGestureConfigs(defaults: UserDefaults, appearance: RuntimeAppearanceSettings) -> [GestureTriggerConfig] {
		TriggerSettingCatalog.windowEntries.compactMap { entry in
			guard defaults.bool(forKey: "\(entry.prefix).enabled") else { return nil }

			let rawFingerCount = defaults.integer(forKey: "\(entry.prefix).gesture")
			guard let fingerCount = TrackpadFingerCount(rawValue: rawFingerCount) else { return nil }
			let settings = PerTriggerSettings.read(prefix: entry.prefix, defaults: defaults)

			return GestureTriggerConfig(
				fingerCount: fingerCount,
				scope: entry.configuration.scope,
				filter: entry.configuration.filter,
				overlayMode: settings.overlayMode,
				peekEnabled: appearance.peekEnabled,
				peekOpacity: appearance.peekOpacity,
				theme: appearance.theme,
				monitorScope: settings.monitorScope,
				invertDirection: settings.invertDirection,
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
			let modifierFlags = rawFlags > 0 ? UInt64(rawFlags) : entry.defaultModifierFlags
			let settings = PerTriggerSettings.read(prefix: entry.prefix, defaults: defaults)
			let keyboardNav = buildKeyboardNavigation(prefix: entry.prefix, defaults: defaults)
			let showOnPress = defaults.object(forKey: "\(entry.prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress

			return DockHoverConfiguration(
				enabled: enabled,
				modifierFlags: modifierFlags,
				monitorScope: settings.monitorScope,
				overlayMode: settings.overlayMode,
				showOnPress: showOnPress,
				invertDirection: settings.invertDirection,
				animate: appearance.animate,
				wrapAround: appearance.wrapAround,
				keyboardNavigation: keyboardNav
			)
		}
	}

	private static func buildKeyboardNavigation(prefix: String, defaults: UserDefaults) -> KeyboardNavigationBinding {
		let kbEnabled = defaults.bool(forKey: "\(prefix).keyboardNav.enabled")
		let forward = buildKeyBinding(flagsKey: "\(prefix).keyboardNav.forwardFlags", keyCodeKey: "\(prefix).keyboardNav.forwardKeyCode", defaults: defaults)
		let backward = buildKeyBinding(flagsKey: "\(prefix).keyboardNav.backwardFlags", keyCodeKey: "\(prefix).keyboardNav.backwardKeyCode", defaults: defaults)
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private static func buildDesktopKeyboardNavigation(defaults: UserDefaults) -> KeyboardNavigationBinding {
		let kbEnabled = defaults.bool(forKey: SettingKey.DesktopSwitch.keyboardNavEnabled)
		let forward = buildKeyBinding(flagsKey: SettingKey.DesktopSwitch.keyboardNavForwardFlags, keyCodeKey: SettingKey.DesktopSwitch.keyboardNavForwardKeyCode, defaults: defaults)
		let backward = buildKeyBinding(flagsKey: SettingKey.DesktopSwitch.keyboardNavBackwardFlags, keyCodeKey: SettingKey.DesktopSwitch.keyboardNavBackwardKeyCode, defaults: defaults)
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private static func buildKeyBinding(flagsKey: String, keyCodeKey: String, defaults: UserDefaults) -> KeyboardHotkeyConfiguration? {
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

private struct PerTriggerSettings: Sendable {
	let overlayMode: OverlayPresentationMode
	let monitorScope: MonitorScope
	let invertDirection: Bool

	static func read(prefix: String, defaults: UserDefaults) -> PerTriggerSettings {
		PerTriggerSettings(
			overlayMode: OverlayPresentationMode(
				rawValue: defaults.string(forKey: "\(prefix).overlay")
					?? SettingDefaults.overlayMode.rawValue
			) ?? SettingDefaults.overlayMode,
			monitorScope: MonitorScope(
				rawValue: defaults.string(forKey: "\(prefix).monitorScope")
					?? SettingDefaults.monitorScope.rawValue
			) ?? SettingDefaults.monitorScope,
			invertDirection: defaults.bool(forKey: "\(prefix).invertDirection")
		)
	}
}
