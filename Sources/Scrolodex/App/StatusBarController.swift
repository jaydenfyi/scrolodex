import AppKit
import ScrolodexCore
import ScrolodexSettings

@MainActor
final class StatusBarController: NSObject {
	private let statusItem = NSStatusBar.system.statusItem(withLength: MenuBarIconConfiguration.statusItemLength)
	private var onOpenSettings: () -> Void
	private var onQuit: () -> Void

	override init() {
		self.onOpenSettings = {}
		self.onQuit = {}
		super.init()
	}

	convenience init(onOpenSettings: @escaping () -> Void, onQuit: @escaping () -> Void) {
		self.init()
		self.onOpenSettings = onOpenSettings
		self.onQuit = onQuit
		configureStatusButton()
	}

	private func configureStatusButton() {
		guard let button = statusItem.button else { return }
		button.title = ""
		button.image = menuBarIcon()
		button.imagePosition = .imageOnly
	}

	private func menuBarIcon() -> NSImage? {
		guard
			let url = Bundle.main.url(
				forResource: MenuBarIconConfiguration.resourceName,
				withExtension: MenuBarIconConfiguration.resourceExtension
			), let image = NSImage(contentsOf: url)
		else {
			return nil
		}
		image.size = NSSize(
			width: MenuBarIconConfiguration.pointSize, height: MenuBarIconConfiguration.pointSize)
		image.isTemplate = true
		return image
	}

	func refresh() {
		let menu = NSMenu()
		menu.delegate = self

		let globallyDisabled = UserDefaults.standard.object(forKey: SettingKey.disabled) as? Bool ?? false

		menu.addItem(makeSectionHeader("Triggers"))

		let triggerEntries: [(name: String, prefix: String, defaultFlags: Double)] = [
			("Under Cursor", "trigger.underCursor.allApps", Double(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue)),
			("All Windows", "trigger.currentScreen.allApps", Double(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskControl.rawValue)),
			// Feature flag: same-app triggers hidden
			// ("App Under Cursor", "trigger.underCursor.sameApp", 0),
			// ("App On Screen", "trigger.currentScreen.sameApp", 0),
			// Feature flag: dock simplified to single option
			// ("Dock Windows", "dockHover.currentMonitor", Double(CGEventFlags.maskAlternate.rawValue)),
			("Dock Windows", "dockHover.allMonitors", Double(CGEventFlags.maskAlternate.rawValue)),
		]

		for entry in triggerEntries {
			menu.addItem(makeTriggerRow(name: entry.name, prefix: entry.prefix, defaultFlags: entry.defaultFlags, dimmed: globallyDisabled))
		}

		menu.addItem(makeDesktopSpacesRow(dimmed: globallyDisabled))
		menu.addItem(.separator())

		let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
		settingsItem.target = self
		menu.addItem(settingsItem)
		menu.addItem(NSMenuItem(title: "Quit Scrolodex", action: #selector(quit), keyEquivalent: "q"))
		menu.items.last?.target = self

		statusItem.menu = menu
	}

	@objc private func openSettings() {
		onOpenSettings()
	}

	@objc private func quit() {
		onQuit()
	}
}

extension StatusBarController: NSMenuDelegate {
	func menuNeedsUpdate(_ menu: NSMenu) {
		refresh()
	}
}

private extension StatusBarController {
	func makeSectionHeader(_ title: String) -> NSMenuItem {
		let item = NSMenuItem()
		let view = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
		let label = NSTextField(labelWithString: title)
		label.font = .systemFont(ofSize: 12, weight: .semibold)
		label.textColor = .labelColor
		label.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(label)
		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
			label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
		])
		item.view = view
		item.isEnabled = false
		return item
	}

	func makeTriggerRow(name: String, prefix: String, defaultFlags: Double, dimmed: Bool = false) -> NSMenuItem {
		let defaults = UserDefaults.standard
		let enabled = defaults.object(forKey: "\(prefix).enabled") as? Bool ?? (defaultFlags > 0)
		let rawFlags = defaults.double(forKey: "\(prefix).flags")
		let effectiveFlags = rawFlags > 0 ? rawFlags : defaultFlags
		let hotkey = HotkeyConfiguration(rawValue: UInt64(effectiveFlags))
		let hotkeyText = enabled && effectiveFlags > 0 ? hotkey.compactDisplayName : nil

		let item = NSMenuItem()
		let rowView = MenuTriggerRowView(
			name: name,
			hotkeyText: hotkeyText,
			isOn: enabled,
			dimmed: dimmed,
			onToggle: dimmed ? { _ in } : { newValue in
				UserDefaults.standard.set(newValue, forKey: "\(prefix).enabled")
			}
		)
		item.view = rowView
		return item
	}

	func makeDesktopSpacesRow(dimmed: Bool = false) -> NSMenuItem {
		let defaults = UserDefaults.standard
		let enabled = defaults.object(forKey: "desktopSwitch.enabled") as? Bool ?? false
		let rawFlags = defaults.object(forKey: "desktopSwitch.flags") as? Double
			?? Double(HotkeyConfiguration.defaultDesktopSwitch.flags.rawValue)
		let hotkey = HotkeyConfiguration(rawValue: UInt64(rawFlags))
		let hotkeyText = enabled && rawFlags > 0 ? hotkey.compactDisplayName : nil

		let item = NSMenuItem()
		let rowView = MenuTriggerRowView(
			name: "Desktop Spaces",
			hotkeyText: hotkeyText,
			isOn: enabled,
			dimmed: dimmed,
			onToggle: dimmed ? { _ in } : { newValue in
				UserDefaults.standard.set(newValue, forKey: "desktopSwitch.enabled")
			}
		)
		item.view = rowView
		return item
	}

}

private final class MenuTriggerRowView: NSView {
	private let onToggle: (Bool) -> Void

	init(name: String, hotkeyText: String?, isOn: Bool, dimmed: Bool = false, onToggle: @escaping (Bool) -> Void) {
		self.onToggle = onToggle

		let rowHeight: CGFloat = 24
		super.init(frame: NSRect(x: 0, y: 0, width: 260, height: rowHeight))

		let nameLabel = NSTextField(labelWithString: name)
		nameLabel.font = .systemFont(ofSize: 13)
		nameLabel.textColor = dimmed ? .tertiaryLabelColor : .labelColor
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(nameLabel)

		let toggle = NSSwitch()
		toggle.state = (dimmed ? false : isOn) ? .on : .off
		toggle.controlSize = .small
		toggle.translatesAutoresizingMaskIntoConstraints = false
		toggle.isEnabled = !dimmed
		addSubview(toggle)

		if let hotkeyText, !hotkeyText.isEmpty {
			let hotkeyLabel = NSTextField(labelWithString: hotkeyText)
			hotkeyLabel.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
			hotkeyLabel.textColor = .tertiaryLabelColor
			hotkeyLabel.alignment = .right
			hotkeyLabel.translatesAutoresizingMaskIntoConstraints = false
			addSubview(hotkeyLabel)

			NSLayoutConstraint.activate([
				hotkeyLabel.trailingAnchor.constraint(equalTo: toggle.leadingAnchor, constant: -6),
				hotkeyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
				hotkeyLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
			])
		}

		NSLayoutConstraint.activate([
			nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
			nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

			toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
			toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
		])

		toggle.target = self
		toggle.action = #selector(toggleChanged(_:))
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) { fatalError() }

	@objc private func toggleChanged(_ sender: NSSwitch) {
		onToggle(sender.state == .on)
	}
}
