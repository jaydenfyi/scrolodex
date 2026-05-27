import Foundation
import ScrolodexCore
import ScrolodexSettings
import Testing

@Suite("Setting keys")
struct SettingKeyTests {
	@Test("registers defaults for shipped triggers")
	func registersDefaultsForShippedTriggers() {
		let suiteName = "SettingKeyTests-\(UUID().uuidString)"
		let defaults = UserDefaults(suiteName: suiteName)!
		defer { defaults.removePersistentDomain(forName: suiteName) }

		SettingKey.registerDefaults(in: defaults)

		#expect(defaults.bool(forKey: "trigger.underCursor.allApps.enabled"))
		#expect(defaults.bool(forKey: "trigger.currentScreen.allApps.enabled"))
		#expect(defaults.bool(forKey: "dockHover.allMonitors.enabled"))
		#expect(defaults.string(forKey: SettingKey.theme) == SettingDefaults.theme.rawValue)
	}
}
