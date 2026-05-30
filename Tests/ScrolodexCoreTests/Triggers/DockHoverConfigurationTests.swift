import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Dock hover configuration")
struct DockHoverConfigurationTests {
	@Test("default configuration values")
	func defaultValues() {
		let config = DockHoverConfiguration()
		#expect(!config.enabled)
		#expect(config.modifierFlags == CGEventFlags.maskAlternate.rawValue)
		#expect(config.monitorScope == .currentMonitor)
	}

	@Test("modifier matches when flag is present")
	func modifierMatches() {
		let config = DockHoverConfiguration(modifierFlags: CGEventFlags.maskAlternate.rawValue)
		#expect(config.modifierMatches(.maskAlternate))
		#expect(!config.modifierMatches(.maskCommand))
	}

	@Test("custom values preserved")
	func customValues() {
		let config = DockHoverConfiguration(
			enabled: true,
			modifierFlags: CGEventFlags.maskControl.rawValue,
			monitorScope: .allMonitors,
			animate: false,
			wrapAround: false
		)
		#expect(config.enabled)
		#expect(config.modifierFlags == CGEventFlags.maskControl.rawValue)
		#expect(config.monitorScope == .allMonitors)
		#expect(!config.animate)
		#expect(!config.wrapAround)
	}

	@Test("carries appearance fields from construction")
	func carriesAppearanceFields() {
		let config = DockHoverConfiguration(
			enabled: true,
			modifierFlags: CGEventFlags.maskAlternate.rawValue,
			peekEnabled: false,
			peekOpacity: 0.5,
			theme: .light
		)
		#expect(config.peekEnabled == false)
		#expect(config.peekOpacity == 0.5)
		#expect(config.theme == .light)
	}

	@Test("appearance fields default to setting defaults")
	func appearanceDefaults() {
		let config = DockHoverConfiguration()
		#expect(config.peekEnabled == SettingDefaults.peekEnabled)
		#expect(config.peekOpacity == SettingDefaults.peekOpacity)
		#expect(config.theme == SettingDefaults.theme)
	}
}
