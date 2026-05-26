import CoreGraphics
import Foundation
import ScrolodexCore
import SwiftUI

@MainActor @Observable
final class TriggerSettingsStore {
	let prefix: String
	private let defaults = UserDefaults.standard

	var enabled: Bool {
		didSet { defaults.set(enabled, forKey: "\(prefix).enabled") }
	}

	var flags: Double {
		didSet { defaults.set(flags, forKey: "\(prefix).flags") }
	}

	var overlay: String {
		didSet { defaults.set(overlay, forKey: "\(prefix).overlay") }
	}

	var monitorScope: String {
		didSet { defaults.set(monitorScope, forKey: "\(prefix).monitorScope") }
	}

	var showOnPress: Bool {
		didSet { defaults.set(showOnPress, forKey: "\(prefix).showOnPress") }
	}

	var invertDirection: Bool {
		didSet { defaults.set(invertDirection, forKey: "\(prefix).invertDirection") }
	}

	var kbNavEnabled: Bool {
		didSet { defaults.set(kbNavEnabled, forKey: "\(prefix).keyboardNav.enabled") }
	}

	var kbNavForwardFlags: Double {
		didSet { defaults.set(kbNavForwardFlags, forKey: "\(prefix).keyboardNav.forwardFlags") }
	}

	var kbNavForwardKeyCode: Double {
		didSet { defaults.set(kbNavForwardKeyCode, forKey: "\(prefix).keyboardNav.forwardKeyCode") }
	}

	var kbNavBackwardFlags: Double {
		didSet { defaults.set(kbNavBackwardFlags, forKey: "\(prefix).keyboardNav.backwardFlags") }
	}

	var kbNavBackwardKeyCode: Double {
		didSet { defaults.set(kbNavBackwardKeyCode, forKey: "\(prefix).keyboardNav.backwardKeyCode") }
	}

	var gesture: Int {
		didSet { defaults.set(gesture, forKey: "\(prefix).gesture") }
	}

	init(prefix: String, defaultFlags: Double = 0, migrationPrefix: String? = nil) {
		self.prefix = prefix
		let d = defaults

		if let migration = migrationPrefix {
			Self.migrateIfNeeded(from: migration, to: prefix, defaults: d)
		}

		self.enabled = d.bool(forKey: "\(prefix).enabled")
		self.flags = d.object(forKey: "\(prefix).flags") as? Double ?? defaultFlags
		self.overlay = d.string(forKey: "\(prefix).overlay") ?? SettingDefaults.overlayMode.rawValue
		self.monitorScope = d.string(forKey: "\(prefix).monitorScope") ?? SettingDefaults.monitorScope.rawValue
		self.showOnPress = d.object(forKey: "\(prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress
		self.invertDirection = d.object(forKey: "\(prefix).invertDirection") as? Bool ?? SettingDefaults.invertDirection
		self.kbNavEnabled = d.object(forKey: "\(prefix).keyboardNav.enabled") as? Bool ?? false
		self.kbNavForwardFlags = d.double(forKey: "\(prefix).keyboardNav.forwardFlags")
		self.kbNavForwardKeyCode = d.double(forKey: "\(prefix).keyboardNav.forwardKeyCode")
		self.kbNavBackwardFlags = d.double(forKey: "\(prefix).keyboardNav.backwardFlags")
		self.kbNavBackwardKeyCode = d.double(forKey: "\(prefix).keyboardNav.backwardKeyCode")
		self.gesture = d.integer(forKey: "\(prefix).gesture")
	}

	convenience init(prefix: String, defaultHotkey: HotkeyConfiguration, migrationPrefix: String? = nil) {
		self.init(prefix: prefix, defaultFlags: Double(defaultHotkey.flags.rawValue), migrationPrefix: migrationPrefix)
	}

	private static func migrateIfNeeded(from old: String, to new: String, defaults: UserDefaults) {
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
