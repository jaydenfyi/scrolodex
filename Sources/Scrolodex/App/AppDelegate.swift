import AppKit
import ScrolodexCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	private let permissionController = PermissionController()
	private let windowStackProvider = CGWindowStackProvider()
	private let overlayController = OverlayController()
	private let accessibilityWindowController = AccessibilityWindowController()

	private var statusBarController: StatusBarController?
	private var navigationCoordinator: NavigationCoordinator?
	private var eventTapController: EventTapController?
	private var dockObserver: DockObserver?
	private var gestureObserver: TrackpadGestureObserver?
	private var permissionPollTimer: Timer?
	private var revocationMonitorTimer: Timer?
	private var settingsWindow: NSWindow?

	func applicationDidFinishLaunching(_ notification: Notification) {
		Log.info("launched bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")

		SettingKey.registerDefaults()

		let sensitivity = UserDefaults.standard.double(forKey: SettingKey.scrollSensitivity)
		let threshold = sensitivity > 0 ? sensitivity : SettingDefaults.scrollSensitivity

		let coordinator = NavigationCoordinator(
			windowStackProvider: windowStackProvider,
			overlayController: overlayController,
			accessibilityWindowController: accessibilityWindowController,
			scrollThreshold: threshold
		)
		navigationCoordinator = coordinator

		statusBarController = StatusBarController(
			onOpenSettings: { [weak self] in self?.openSettings() },
			onQuit: { NSApplication.shared.terminate(nil) }
		)
		statusBarController?.refresh()

		if permissionController.allPermissionsGranted {
			startEventTap(with: coordinator)
		} else {
			Log.info("permissions not granted; opening settings")
			openSettings()
			startPermissionPolling(with: coordinator)
		}

		NotificationCenter.default.addObserver(
			forName: UserDefaults.didChangeNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.handleSettingsChanged()
			}
		}

		NotificationCenter.default.addObserver(
			forName: .scrolodexPauseEventTap,
			object: nil,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				self?.eventTapController?.stop()
			}
		}

		NotificationCenter.default.addObserver(
			forName: .scrolodexResumeEventTap,
			object: nil,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self, let coordinator = self.navigationCoordinator else { return }
				self.restartEventTap(with: coordinator)
			}
		}
	}

	private func openSettings() {
		if let window = settingsWindow {
			window.makeKeyAndOrderFront(nil)
			NSApp.activate(ignoringOtherApps: true)
			return
		}

		let settingsView = SettingsView()
		let window = NSWindow(
			contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.title = "Scrolodex Settings"
		window.contentView = NSHostingView(rootView: settingsView)
		window.center()
		window.isReleasedWhenClosed = false
		window.delegate = self
		window.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
		settingsWindow = window
	}

	private func handleSettingsChanged() {
		guard let coordinator = navigationCoordinator else { return }
		statusBarController?.refresh()
		restartEventTap(with: coordinator)
	}

	private func buildTriggers(globalVisual: GlobalVisualSettings) -> [TriggerHotkey] {
		let defaults = UserDefaults.standard

		let configs: [(TriggerConfiguration, String)] = [
			(TriggerConfiguration(scope: .underCursor, filter: .allApps), "trigger.underCursor.allApps"),
			(
				TriggerConfiguration(scope: .currentScreen, filter: .allApps),
				"trigger.currentScreen.allApps"
			),
			// Feature flag: same-app triggers disabled
			// (TriggerConfiguration(scope: .underCursor, filter: .sameApp), "trigger.underCursor.sameApp"),
			// (
			// 	TriggerConfiguration(scope: .currentScreen, filter: .sameApp),
			// 	"trigger.currentScreen.sameApp"
			// ),
		]

		return configs.compactMap { config, prefix in
			let enabled = defaults.bool(forKey: "\(prefix).enabled")
			guard enabled else { return nil }

			let rawFlags = defaults.double(forKey: "\(prefix).flags")
			let flags = CGEventFlags(rawValue: UInt64(rawFlags))
			guard !flags.isEmpty else { return nil }

			let overlayRaw =
				defaults.string(forKey: "\(prefix).overlay")
				?? SettingDefaults.overlayMode.rawValue
			let overlayMode = OverlayPresentationMode(rawValue: overlayRaw) ?? SettingDefaults.overlayMode
			let monitorScopeRaw =
				defaults.string(forKey: "\(prefix).monitorScope")
				?? SettingDefaults.monitorScope.rawValue
			let monitorScope = MonitorScope(rawValue: monitorScopeRaw) ?? SettingDefaults.monitorScope

			let keyboardNav = buildKeyboardNavigation(prefix: prefix)

			let showOnPress = defaults.object(forKey: "\(prefix).showOnPress") as? Bool ?? SettingDefaults.showOnPress
			let invertDirection = defaults.bool(forKey: "\(prefix).invertDirection")

			return TriggerHotkey(
				configuration: config,
				hotkey: HotkeyConfiguration(flags: flags),
				overlayMode: overlayMode,
				peekEnabled: globalVisual.peekEnabled,
				peekOpacity: globalVisual.peekOpacity,
				theme: globalVisual.theme,
				monitorScope: monitorScope,
				showOnPress: showOnPress,
				invertDirection: invertDirection,
				animate: globalVisual.animate,
				wrapAround: globalVisual.wrapAround,
				keyboardNavigation: keyboardNav
			)
		}
	}

	private func buildGestureConfigs(globalVisual: GlobalVisualSettings) -> [GestureTriggerConfig] {
		let defaults = UserDefaults.standard

		let triggerEntries: [(TriggerConfiguration, String)] = [
			(TriggerConfiguration(scope: .underCursor, filter: .allApps), "trigger.underCursor.allApps"),
			(
				TriggerConfiguration(scope: .currentScreen, filter: .allApps),
				"trigger.currentScreen.allApps"
			),
			// Feature flag: same-app triggers disabled
			// (TriggerConfiguration(scope: .underCursor, filter: .sameApp), "trigger.underCursor.sameApp"),
			// (
			// 	TriggerConfiguration(scope: .currentScreen, filter: .sameApp),
			// 	"trigger.currentScreen.sameApp"
			// ),
		]

		return triggerEntries.compactMap { config, prefix in
			let enabled = defaults.bool(forKey: "\(prefix).enabled")
			guard enabled else { return nil }

			let rawFingerCount = defaults.integer(forKey: "\(prefix).gesture")
			guard let fingerCount = TrackpadFingerCount(rawValue: rawFingerCount) else { return nil }

			let overlayRaw =
				defaults.string(forKey: "\(prefix).overlay")
				?? OverlayPresentationMode.default.rawValue
			let overlayMode = OverlayPresentationMode(rawValue: overlayRaw) ?? .default
			let monitorScopeRaw =
				defaults.string(forKey: "\(prefix).monitorScope")
				?? MonitorScope.currentMonitor.rawValue
			let monitorScope = MonitorScope(rawValue: monitorScopeRaw) ?? .currentMonitor
			let invertDirection = defaults.bool(forKey: "\(prefix).invertDirection")

			return GestureTriggerConfig(
				fingerCount: fingerCount,
				scope: config.scope,
				filter: config.filter,
				overlayMode: overlayMode,
				peekEnabled: globalVisual.peekEnabled,
				peekOpacity: globalVisual.peekOpacity,
				theme: globalVisual.theme,
				monitorScope: monitorScope,
				invertDirection: invertDirection,
				animate: globalVisual.animate,
				wrapAround: globalVisual.wrapAround
			)
		}
	}

	private func buildDesktopTriggers() -> [DesktopSwitchTrigger] {
		let defaults = UserDefaults.standard
		let enabled = defaults.bool(forKey: SettingKey.DesktopSwitch.enabled)
		guard enabled else { return [] }

		let rawFlags =
			defaults.object(forKey: SettingKey.DesktopSwitch.flags) as? Double
			?? Double(HotkeyConfiguration.defaultDesktopSwitch.flags.rawValue)
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		guard !flags.isEmpty else { return [] }

		let invertDirection = defaults.bool(forKey: SettingKey.DesktopSwitch.invertDirection)
		let animateScroll = defaults.object(forKey: SettingKey.DesktopSwitch.animate) as? Bool ?? SettingDefaults.desktopSwitchAnimate
		let wrapAround = defaults.object(forKey: SettingKey.DesktopSwitch.wrapAround) as? Bool ?? SettingDefaults.desktopSwitchWrapAround
		let keyboardNav = buildDesktopKeyboardNavigation()

		return [
			DesktopSwitchTrigger(
				hotkey: HotkeyConfiguration(flags: flags),
				invertDirection: invertDirection,
				animateScroll: animateScroll,
				wrapAround: wrapAround,
				keyboardNavigation: keyboardNav
			)
		]
	}

	private func buildDesktopKeyboardNavigation() -> KeyboardNavigationBinding {
		let defaults = UserDefaults.standard
		let kbEnabled = defaults.bool(forKey: SettingKey.DesktopSwitch.keyboardNavEnabled)
		let forward = buildDesktopKeyBinding(direction: "forward")
		let backward = buildDesktopKeyBinding(direction: "backward")
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private func buildDesktopKeyBinding(direction: String) -> KeyboardHotkeyConfiguration? {
		let defaults = UserDefaults.standard
		let flagsKey =
			direction == "forward"
			? SettingKey.DesktopSwitch.keyboardNavForwardFlags
			: SettingKey.DesktopSwitch.keyboardNavBackwardFlags
		let keyCodeKey =
			direction == "forward"
			? SettingKey.DesktopSwitch.keyboardNavForwardKeyCode
			: SettingKey.DesktopSwitch.keyboardNavBackwardKeyCode
		let rawFlags = defaults.double(forKey: flagsKey)
		let rawKeyCode = defaults.double(forKey: keyCodeKey)
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		let keyCode = CGKeyCode(rawKeyCode)
		guard keyCode != 0 else { return nil }
		return KeyboardHotkeyConfiguration(flags: flags, keyCode: keyCode)
	}

	private func buildKeyboardNavigation(prefix: String) -> KeyboardNavigationBinding {
		let kbEnabled = UserDefaults.standard.bool(forKey: "\(prefix).keyboardNav.enabled")
		let forward = buildKeyBinding(prefix: prefix, direction: "forward")
		let backward = buildKeyBinding(prefix: prefix, direction: "backward")
		return KeyboardNavigationBinding(enabled: kbEnabled, forward: forward, backward: backward)
	}

	private func buildKeyBinding(prefix: String, direction: String) -> KeyboardHotkeyConfiguration? {
		let rawFlags = UserDefaults.standard.double(forKey: "\(prefix).keyboardNav.\(direction)Flags")
		let rawKeyCode = UserDefaults.standard.double(forKey: "\(prefix).keyboardNav.\(direction)KeyCode")
		let flags = CGEventFlags(rawValue: UInt64(rawFlags))
		let keyCode = CGKeyCode(rawKeyCode)
		guard keyCode != 0 else { return nil }
		return KeyboardHotkeyConfiguration(flags: flags, keyCode: keyCode)
	}

	private func startEventTap(with coordinator: NavigationCoordinator) {
		guard eventTapController == nil else { return }
		guard permissionController.allPermissionsGranted else {
			Log.info("permissions missing; not starting event tap")
			startPermissionPolling(with: coordinator)
			return
		}

		let globallyDisabled = UserDefaults.standard.object(forKey: SettingKey.disabled) as? Bool ?? false
		guard !globallyDisabled else {
			Log.info("globally disabled; skipping event tap")
			return
		}

		let defaults = UserDefaults.standard
		let globalVisual = GlobalVisualSettings.read(from: defaults)

		let triggers = buildTriggers(globalVisual: globalVisual)
		let desktopTriggers = buildDesktopTriggers()
		let sensitivity = defaults.double(forKey: SettingKey.scrollSensitivity)
		let threshold = sensitivity > 0 ? sensitivity : SettingDefaults.scrollSensitivity

		let dockConfigs = buildDockHoverConfigurations(globalVisual: globalVisual)
		let enabledDockConfigs = dockConfigs.filter(\.enabled)
		if !enabledDockConfigs.isEmpty, dockObserver == nil {
			let observer = DockObserver()
			observer.onHoverChanged = { info in
				Log.debug("dock hover changed app=%@", info?.localizedName ?? "none")
			}
			observer.start()
			dockObserver = observer
		}

		guard !triggers.isEmpty || !desktopTriggers.isEmpty || !enabledDockConfigs.isEmpty else {
			Log.info("no triggers enabled; skipping event tap")
			return
		}

		let gestureConfigs = buildGestureConfigs(globalVisual: globalVisual)

		let dockHandler = DockActionHandler(
			coordinator: coordinator,
			scrollThreshold: threshold,
			peekOpacity: globalVisual.peekOpacity,
			theme: globalVisual.theme
		)

		let eventTapController = EventTapController(
			coordinator: coordinator,
			triggers: triggers,
			desktopTriggers: desktopTriggers,
			desktopScrollThreshold: threshold,
			dockObserver: dockObserver,
			dockHoverConfigs: enabledDockConfigs,
			dockHandler: dockHandler,
			permissionCheck: { [weak self] in
				self?.permissionController.allPermissionsGranted ?? false
			}
		)
		eventTapController.start()
		self.eventTapController = eventTapController

		if !gestureConfigs.isEmpty {
			let observer = TrackpadGestureObserver(
				coordinator: coordinator,
				scrollThreshold: threshold,
				dockObserver: dockObserver,
				dockHoverConfigs: enabledDockConfigs,
				dockHandler: dockHandler
			)
			observer.start(triggerConfigs: gestureConfigs)
			self.gestureObserver = observer
		} else {
			gestureObserver?.stop()
			gestureObserver = nil
		}

		startRevocationMonitor(with: coordinator)
	}

	private func buildDockHoverConfigurations(globalVisual: GlobalVisualSettings) -> [DockHoverConfiguration] {
		return [
			// Feature flag: dock simplified to single option
			// DockHoverConfiguration.fromUserDefaults(
			// 	prefix: "dockHover.currentMonitor", defaultMonitorScope: .currentMonitor,
			// 	globalAnimate: globalAnimate, globalWrapAround: globalWrapAround),
			DockHoverConfiguration.fromUserDefaults(
				prefix: "dockHover.allMonitors", defaultMonitorScope: .allMonitors,
				globalAnimate: globalVisual.animate, globalWrapAround: globalVisual.wrapAround,
				migrationPrefix: "dockHover"),
		]
	}

	private func restartEventTap(with coordinator: NavigationCoordinator) {
		dockObserver?.stop()
		dockObserver = nil
		gestureObserver?.stop()
		gestureObserver = nil
		eventTapController?.stop()
		eventTapController = nil
		revocationMonitorTimer?.invalidate()
		revocationMonitorTimer = nil
		startEventTap(with: coordinator)
	}

	private func startRevocationMonitor(with coordinator: NavigationCoordinator) {
		revocationMonitorTimer?.invalidate()
		revocationMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self else { return }
				if !self.permissionController.allPermissionsGranted {
					Log.info("permissions revoked; stopping event tap")
					self.eventTapController?.stop()
					self.eventTapController = nil
					self.revocationMonitorTimer?.invalidate()
					self.revocationMonitorTimer = nil
					self.startPermissionPolling(with: coordinator)
				}
			}
		}
	}

	private func startPermissionPolling(with coordinator: NavigationCoordinator) {
		guard permissionPollTimer == nil else { return }
		permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
			Task { @MainActor [weak self] in
				guard let self else { return }
				if self.permissionController.allPermissionsGranted {
					Log.info("all permissions granted; starting event tap")
					self.startEventTap(with: coordinator)
					self.permissionPollTimer?.invalidate()
					self.permissionPollTimer = nil
				}
			}
		}
	}
}

extension AppDelegate: NSWindowDelegate {
	func windowWillClose(_ notification: Notification) {
		if let window = notification.object as? NSWindow, window == settingsWindow {
			settingsWindow = nil
		}
	}
}
