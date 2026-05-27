import Foundation
import ScrolodexCore

public struct RuntimeAppearanceSettings: Sendable, Equatable {
	public let theme: OverlayTheme
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let animate: Bool
	public let wrapAround: Bool

	public init(theme: OverlayTheme, peekEnabled: Bool, peekOpacity: Double, animate: Bool, wrapAround: Bool) {
		self.theme = theme
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.animate = animate
		self.wrapAround = wrapAround
	}

	public static func read(from defaults: UserDefaults = .standard) -> RuntimeAppearanceSettings {
		let theme = OverlayTheme(
			rawValue: defaults.string(forKey: SettingKey.theme) ?? SettingDefaults.theme.rawValue
		) ?? SettingDefaults.theme
		return RuntimeAppearanceSettings(
			theme: theme,
			peekEnabled: defaults.object(forKey: SettingKey.peekEnabled) as? Bool ?? SettingDefaults.peekEnabled,
			peekOpacity: defaults.object(forKey: SettingKey.peekOpacity) as? Double ?? SettingDefaults.peekOpacity,
			animate: defaults.object(forKey: SettingKey.animate) as? Bool ?? SettingDefaults.animate,
			wrapAround: defaults.object(forKey: SettingKey.wrapAround) as? Bool ?? SettingDefaults.wrapAround
		)
	}
}
