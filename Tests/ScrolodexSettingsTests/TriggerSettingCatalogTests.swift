import CoreGraphics
import ScrolodexCore
import ScrolodexSettings
import Testing

@Suite("Trigger setting catalog")
struct TriggerSettingCatalogTests {
	@Test("contains only currently shipped window entries")
	func shippedWindowEntries() {
		#expect(TriggerSettingCatalog.windowEntries.map(\.prefix) == [
			"trigger.underCursor.allApps",
			"trigger.currentScreen.allApps",
		])
	}

	@Test("contains only currently shipped Dock Hover entries")
	func shippedDockHoverEntries() {
		#expect(TriggerSettingCatalog.dockHoverEntries.map(\.prefix) == [
			"dockHover.allMonitors",
		])
	}

	@Test("window entries carry domain query settings")
	func windowEntriesCarryDomainQuerySettings() {
		let underCursor = TriggerSettingCatalog.windowEntries[0]
		#expect(underCursor.configuration.scope == .underCursor)
		#expect(underCursor.configuration.filter == .allApps)

		let currentScreen = TriggerSettingCatalog.windowEntries[1]
		#expect(currentScreen.configuration.scope == .currentScreen)
		#expect(currentScreen.configuration.filter == .allApps)
	}

	@Test("entries have non-zero default modifier flags")
	func entriesHaveNonZeroFlags() {
		for entry in TriggerSettingCatalog.windowEntries {
			#expect(entry.defaultModifierFlags != 0)
		}
		for entry in TriggerSettingCatalog.dockHoverEntries {
			#expect(entry.defaultModifierFlags != 0)
		}
	}
}
