import AppKit
import ScrolodexCore
import ScrolodexSettings
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
	private var runtimeConfigurationChangeDetector: RuntimeConfigurationChangeDetector?
	private var permissionPollTimer: Timer?
	private var revocationMonitorTimer: Timer?
	private var settingsWindow: NSWindow?

	func applicationDidFinishLaunching(_ notification: Notification) {
		Log.debugEnabled = UserDefaults.standard.bool(forKey: "debugLogging")
		Log.info("launched bundle=%@", Bundle.main.bundleIdentifier ?? "unknown")

		SettingKey.registerDefaults()

		let runtime = UserDefaultsRuntimeConfigurationReader.read()
		runtimeConfigurationChangeDetector = RuntimeConfigurationChangeDetector(current: runtime)

		let coordinator = NavigationCoordinator(
			windowStackProvider: windowStackProvider,
			overlayController: overlayController,
			accessibilityWindowController: accessibilityWindowController,
			scrollThreshold: runtime.scrollThreshold,
			desktopApplicationNameProvider: { pid in
				NSRunningApplication(processIdentifier: pid)?.localizedName
			}
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

		let workspaceNotifications = NSWorkspace.shared.notificationCenter
		for (name, reason) in [
			(NSWorkspace.didWakeNotification, "wake"),
			(NSWorkspace.sessionDidBecomeActiveNotification, "session active"),
		] {
			workspaceNotifications.addObserver(
				forName: name,
				object: nil,
				queue: .main
			) { [weak self] _ in
				Task { @MainActor [weak self] in
					guard let self, let coordinator = self.navigationCoordinator else { return }
					Log.info("system resume detected reason=%@; restarting event taps", reason as NSString)
					self.restartEventTap(with: coordinator)
				}
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
		let runtime = UserDefaultsRuntimeConfigurationReader.read()
		if runtimeConfigurationChangeDetector?.updateIfChanged(runtime) == false {
			return
		}
		statusBarController?.refresh()
		restartEventTap(with: coordinator)
	}

	private func startEventTap(with coordinator: NavigationCoordinator) {
		guard eventTapController == nil else { return }
		guard permissionController.allPermissionsGranted else {
			Log.info("permissions missing; not starting event tap")
			startPermissionPolling(with: coordinator)
			return
		}

		let runtime = UserDefaultsRuntimeConfigurationReader.read()
		guard !runtime.globallyDisabled else {
			Log.info("globally disabled; skipping event tap")
			return
		}

		let enabledDockConfigs = runtime.dockHoverConfigurations.filter(\.enabled)
		if !enabledDockConfigs.isEmpty, dockObserver == nil {
			let observer = DockObserver()
			observer.onHoverChanged = { info in
				Log.debug("dock hover changed app=%@", info?.localizedName ?? "none")
			}
			observer.start()
			dockObserver = observer
		}

		guard !runtime.triggers.isEmpty || !runtime.desktopTriggers.isEmpty || !enabledDockConfigs.isEmpty else {
			Log.info("no triggers enabled; skipping event tap")
			return
		}

		let dockHandler = DockActionHandler(
			coordinator: coordinator,
			scrollThreshold: runtime.scrollThreshold
		)
		let cursorTrackingState = WindowCursorTrackingState()

		let eventTapController = EventTapController(
			coordinator: coordinator,
			triggers: runtime.triggers,
			desktopTriggers: runtime.desktopTriggers,
			desktopScrollThreshold: runtime.scrollThreshold,
			dockObserver: dockObserver,
			dockHoverConfigs: enabledDockConfigs,
			dockHandler: dockHandler,
			cursorTrackingState: cursorTrackingState,
			permissionCheck: { [weak self] in
				self?.permissionController.allPermissionsGranted ?? false
			}
		)
		eventTapController.start()
		self.eventTapController = eventTapController

		if !runtime.gestureConfigs.isEmpty {
			let observer = TrackpadGestureObserver(
				coordinator: coordinator,
				scrollThreshold: runtime.scrollThreshold,
				dockObserver: dockObserver,
				dockHoverConfigs: enabledDockConfigs,
				dockHandler: dockHandler,
				cursorTrackingState: cursorTrackingState
			)
			observer.start(triggerConfigs: runtime.gestureConfigs)
			self.gestureObserver = observer
		} else {
			gestureObserver?.stop()
			gestureObserver = nil
		}

		startRevocationMonitor(with: coordinator)
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
