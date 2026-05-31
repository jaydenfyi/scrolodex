import CoreGraphics
import Foundation
import ScrolodexCore
import ScrolodexSettings
import Testing

@Suite("Runtime configuration reader")
struct RuntimeConfigurationReaderTests {
	private func makeDefaults(overrides: [String: Any] = [:]) -> UserDefaults {
		let suiteName = "RuntimeConfigTests-\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		SettingKey.registerDefaults(in: defaults)
		for (key, value) in overrides {
			defaults.set(value, forKey: key)
		}
		return defaults
	}

	@Test("default values produce valid configuration")
	func defaultValues() {
		let defaults = makeDefaults()
		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)

		#expect(!config.globallyDisabled)
		#expect(config.appearance.theme == SettingDefaults.theme)
		#expect(config.triggers.count == 2)
		#expect(config.desktopTriggers.isEmpty)
		#expect(config.dockHoverConfigurations.count == 1)
	}

	@Test("disabled trigger is omitted")
	func disabledTriggerOmitted() {
		let defaults = makeDefaults(overrides: [
			"trigger.underCursor.allApps.enabled": false,
		])
		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)

		#expect(config.triggers.count == 1)
		#expect(config.triggers[0].configuration.scope == .currentScreen)
	}

	@Test("gesture config resolves only for valid finger count")
	func gestureConfigRequiresValidFingerCount() {
		let defaults = makeDefaults(overrides: [
			"trigger.underCursor.allApps.gesture": 3,
		])
		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)
		#expect(!config.gestureConfigs.isEmpty)

		let defaultsNoGesture = makeDefaults(overrides: [
			"trigger.underCursor.allApps.gesture": 0,
		])
		let configNoGesture = UserDefaultsRuntimeConfigurationReader.read(from: defaultsNoGesture)
		#expect(configNoGesture.gestureConfigs.isEmpty)
	}

	@Test("dock hover migration from old prefix")
	func dockHoverMigration() {
		let defaults = makeDefaults()
		defaults.removeObject(forKey: "dockHover.allMonitors.flags")
		defaults.set(Double(CGEventFlags.maskControl.rawValue), forKey: "dockHover.modifierFlags")
		defaults.set(true, forKey: "dockHover.enabled")

		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)

		#expect(config.dockHoverConfigurations.count == 1)
		#expect(config.dockHoverConfigurations[0].modifierFlags == CGEventFlags.maskControl.rawValue)
	}

	@Test("desktop switch resolves when enabled")
	func desktopSwitchResolves() {
		let defaults = makeDefaults(overrides: [
			"desktopSwitch.enabled": true,
			"desktopSwitch.flags": Double(CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskShift.rawValue),
		])
		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)

		#expect(config.desktopTriggers.count == 1)
		#expect(config.desktopTriggers[0].hotkey.flags == [.maskAlternate, .maskShift])
	}

	@Test("globally disabled flag respected")
	func globallyDisabled() {
		let defaults = makeDefaults(overrides: [
			SettingKey.disabled: true,
		])
		let config = UserDefaultsRuntimeConfigurationReader.read(from: defaults)

		#expect(config.globallyDisabled)
	}

	@Test("change detector ignores notifications when runtime configuration is unchanged")
	func changeDetectorIgnoresUnchangedRuntimeConfiguration() {
		let defaults = makeDefaults(overrides: [
			"desktopSwitch.enabled": true,
		])
		var detector = RuntimeConfigurationChangeDetector(current: UserDefaultsRuntimeConfigurationReader.read(from: defaults))

		defaults.set(true, forKey: "debugLogging")
		let changed = detector.updateIfChanged(UserDefaultsRuntimeConfigurationReader.read(from: defaults))

		#expect(!changed)
	}

	@Test("change detector reports changed runtime configuration")
	func changeDetectorReportsChangedRuntimeConfiguration() {
		let defaults = makeDefaults(overrides: [
			"desktopSwitch.enabled": true,
		])
		var detector = RuntimeConfigurationChangeDetector(current: UserDefaultsRuntimeConfigurationReader.read(from: defaults))

		defaults.set(false, forKey: "desktopSwitch.enabled")
		let changed = detector.updateIfChanged(UserDefaultsRuntimeConfigurationReader.read(from: defaults))

		#expect(changed)
	}
}
