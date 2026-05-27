import Foundation
import ScrolodexCore
import ScrolodexSettings

struct GlobalVisualSettings: Sendable {
	let theme: OverlayTheme
	let peekEnabled: Bool
	let peekOpacity: Double
	let animate: Bool
	let wrapAround: Bool

	static func read(from defaults: UserDefaults = .standard) -> GlobalVisualSettings {
		let theme = OverlayTheme(
			rawValue: defaults.string(forKey: SettingKey.theme) ?? SettingDefaults.theme.rawValue
		) ?? SettingDefaults.theme
		return GlobalVisualSettings(
			theme: theme,
			peekEnabled: defaults.object(forKey: SettingKey.peekEnabled) as? Bool ?? SettingDefaults.peekEnabled,
			peekOpacity: defaults.object(forKey: SettingKey.peekOpacity) as? Double ?? SettingDefaults.peekOpacity,
			animate: defaults.object(forKey: SettingKey.animate) as? Bool ?? SettingDefaults.animate,
			wrapAround: defaults.object(forKey: SettingKey.wrapAround) as? Bool ?? SettingDefaults.wrapAround
		)
	}
}
