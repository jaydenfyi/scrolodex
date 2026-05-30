import CoreGraphics
import Foundation
import ScrolodexCore
import ScrolodexSettings
import SwiftUI

@MainActor @Observable
final class TriggerSettingsStore {
	let prefix: String
	private let defaultFlags: Double
	private let defaults = UserDefaults.standard
	@ObservationIgnored nonisolated(unsafe) private var observer: NSObjectProtocol?
	private var isApplyingExternalSnapshot = false

	var enabled: Bool {
		didSet { writeIfNotApplyingExternalSnapshot("enabled", enabled) }
	}

	var flags: Double {
		didSet { writeIfNotApplyingExternalSnapshot("flags", flags) }
	}

	var overlay: String {
		didSet { writeIfNotApplyingExternalSnapshot("overlay", overlay) }
	}

	var monitorScope: String {
		didSet { writeIfNotApplyingExternalSnapshot("monitorScope", monitorScope) }
	}

	var showOnPress: Bool {
		didSet { writeIfNotApplyingExternalSnapshot("showOnPress", showOnPress) }
	}

	var invertDirection: Bool {
		didSet { writeIfNotApplyingExternalSnapshot("invertDirection", invertDirection) }
	}

	var kbNavEnabled: Bool {
		didSet { writeIfNotApplyingExternalSnapshot("keyboardNav.enabled", kbNavEnabled) }
	}

	var kbNavForwardFlags: Double {
		didSet { writeIfNotApplyingExternalSnapshot("keyboardNav.forwardFlags", kbNavForwardFlags) }
	}

	var kbNavForwardKeyCode: Double {
		didSet { writeIfNotApplyingExternalSnapshot("keyboardNav.forwardKeyCode", kbNavForwardKeyCode) }
	}

	var kbNavBackwardFlags: Double {
		didSet { writeIfNotApplyingExternalSnapshot("keyboardNav.backwardFlags", kbNavBackwardFlags) }
	}

	var kbNavBackwardKeyCode: Double {
		didSet { writeIfNotApplyingExternalSnapshot("keyboardNav.backwardKeyCode", kbNavBackwardKeyCode) }
	}

	var gesture: Int {
		didSet { writeIfNotApplyingExternalSnapshot("gesture", gesture) }
	}

	init(prefix: String, defaultFlags: Double = 0, migrationPrefix: String? = nil) {
		self.prefix = prefix
		self.defaultFlags = defaultFlags
		let d = defaults

		if let migration = migrationPrefix {
			Self.migrateIfNeeded(from: migration, to: prefix, defaults: d)
		}

		let snapshot = Self.readSnapshot(prefix: prefix, defaultFlags: defaultFlags, defaults: d)
		self.enabled = snapshot.enabled
		self.flags = snapshot.flags
		self.overlay = snapshot.overlay
		self.monitorScope = snapshot.monitorScope
		self.showOnPress = snapshot.showOnPress
		self.invertDirection = snapshot.invertDirection
		self.kbNavEnabled = snapshot.kbNavEnabled
		self.kbNavForwardFlags = snapshot.kbNavForwardFlags
		self.kbNavForwardKeyCode = snapshot.kbNavForwardKeyCode
		self.kbNavBackwardFlags = snapshot.kbNavBackwardFlags
		self.kbNavBackwardKeyCode = snapshot.kbNavBackwardKeyCode
		self.gesture = snapshot.gesture

		self.observer = NotificationCenter.default.addObserver(
			forName: UserDefaults.didChangeNotification,
			object: defaults,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.syncFromDefaults()
			}
		}
	}

	convenience init(prefix: String, defaultHotkey: HotkeyConfiguration, migrationPrefix: String? = nil) {
		self.init(prefix: prefix, defaultFlags: Double(defaultHotkey.flags.rawValue), migrationPrefix: migrationPrefix)
	}

	convenience init(entry: TriggerSettingCatalogEntry, defaultHotkey: HotkeyConfiguration, migrationPrefix: String? = nil) {
		self.init(prefix: entry.prefix, defaultFlags: Double(defaultHotkey.flags.rawValue), migrationPrefix: migrationPrefix)
	}

	convenience init(entry: TriggerSettingCatalogEntry, migrationPrefix: String? = nil) {
		self.init(prefix: entry.prefix, defaultFlags: Double(entry.defaultModifierFlags), migrationPrefix: migrationPrefix)
	}

	deinit {
		if let observer { NotificationCenter.default.removeObserver(observer) }
	}

	// MARK: - External sync

	/// Re-reads all trigger settings from UserDefaults, picking up changes made externally
	/// (for example, from the menu bar dropdown).
	private func syncFromDefaults() {
		apply(Self.readSnapshot(prefix: prefix, defaultFlags: defaultFlags, defaults: defaults))
	}

	private func apply(_ snapshot: TriggerSettingsSnapshot) {
		guard snapshot != currentSnapshot else { return }

		isApplyingExternalSnapshot = true
		defer { isApplyingExternalSnapshot = false }

		enabled = snapshot.enabled
		flags = snapshot.flags
		overlay = snapshot.overlay
		monitorScope = snapshot.monitorScope
		showOnPress = snapshot.showOnPress
		invertDirection = snapshot.invertDirection
		kbNavEnabled = snapshot.kbNavEnabled
		kbNavForwardFlags = snapshot.kbNavForwardFlags
		kbNavForwardKeyCode = snapshot.kbNavForwardKeyCode
		kbNavBackwardFlags = snapshot.kbNavBackwardFlags
		kbNavBackwardKeyCode = snapshot.kbNavBackwardKeyCode
		gesture = snapshot.gesture
	}

	private var currentSnapshot: TriggerSettingsSnapshot {
		TriggerSettingsSnapshot(
			enabled: enabled,
			flags: flags,
			overlay: overlay,
			monitorScope: monitorScope,
			showOnPress: showOnPress,
			invertDirection: invertDirection,
			kbNavEnabled: kbNavEnabled,
			kbNavForwardFlags: kbNavForwardFlags,
			kbNavForwardKeyCode: kbNavForwardKeyCode,
			kbNavBackwardFlags: kbNavBackwardFlags,
			kbNavBackwardKeyCode: kbNavBackwardKeyCode,
			gesture: gesture
		)
	}

	private func writeIfNotApplyingExternalSnapshot(_ suffix: String, _ value: Any) {
		guard !isApplyingExternalSnapshot else { return }
		defaults.set(value, forKey: "\(prefix).\(suffix)")
	}

	private static func readSnapshot(
		prefix: String,
		defaultFlags: Double,
		defaults: UserDefaults
	) -> TriggerSettingsSnapshot {
		TriggerSettingsSnapshot(
			enabled: defaults.bool(forKey: "\(prefix).enabled"),
			flags: defaults.object(forKey: "\(prefix).flags") as? Double ?? defaultFlags,
			overlay: defaults.string(forKey: "\(prefix).overlay") ?? SettingDefaults.overlayMode.rawValue,
			monitorScope: defaults.string(forKey: "\(prefix).monitorScope") ?? SettingDefaults.monitorScope.rawValue,
			showOnPress: defaults.object(forKey: "\(prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress,
			invertDirection: defaults.object(forKey: "\(prefix).invertDirection") as? Bool ?? SettingDefaults.invertDirection,
			kbNavEnabled: defaults.object(forKey: "\(prefix).keyboardNav.enabled") as? Bool ?? false,
			kbNavForwardFlags: defaults.double(forKey: "\(prefix).keyboardNav.forwardFlags"),
			kbNavForwardKeyCode: defaults.double(forKey: "\(prefix).keyboardNav.forwardKeyCode"),
			kbNavBackwardFlags: defaults.double(forKey: "\(prefix).keyboardNav.backwardFlags"),
			kbNavBackwardKeyCode: defaults.double(forKey: "\(prefix).keyboardNav.backwardKeyCode"),
			gesture: defaults.integer(forKey: "\(prefix).gesture")
		)
	}

	// MARK: - Migration

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

private struct TriggerSettingsSnapshot: Equatable {
	let enabled: Bool
	let flags: Double
	let overlay: String
	let monitorScope: String
	let showOnPress: Bool
	let invertDirection: Bool
	let kbNavEnabled: Bool
	let kbNavForwardFlags: Double
	let kbNavForwardKeyCode: Double
	let kbNavBackwardFlags: Double
	let kbNavBackwardKeyCode: Double
	let gesture: Int
}
