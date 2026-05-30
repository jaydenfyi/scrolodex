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

	@Test("catalog entries carry enabled defaults")
	func entriesCarryEnabledDefaults() {
		#expect(TriggerSettingCatalog.windowEntries[0].enabled == true)
		#expect(TriggerSettingCatalog.windowEntries[1].enabled == true)
		#expect(TriggerSettingCatalog.dockHoverEntries[0].enabled == true)
		#expect(TriggerSettingCatalog.desktopEntries[0].enabled == false)
	}

	@Test("window and dock entries have keyboard nav defaults")
	func windowAndDockEntriesHaveKeyboardNavDefaults() throws {
		for entry in TriggerSettingCatalog.windowEntries {
			let kb = try #require(entry.keyboardNavDefaults)
			#expect(kb.enabled == true)
			#expect(kb.forwardKeyCode == 50.0)
			#expect(kb.backwardKeyCode == 50.0)
		}
		let dock = try #require(TriggerSettingCatalog.dockHoverEntries[0].keyboardNavDefaults)
		#expect(dock.enabled == true)
	}

	@Test("desktop entry has keyboard nav defaults with disabled binding")
	func desktopEntryKeyboardNavDefaults() throws {
		let kb = try #require(TriggerSettingCatalog.desktopEntries[0].keyboardNavDefaults)
		#expect(kb.enabled == false)
	}
}
