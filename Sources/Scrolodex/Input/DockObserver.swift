import AppKit
import ApplicationServices
import Foundation
import ScrolodexCore

struct DockHoverInfo: Sendable {
	let bundleIdentifier: String
	let processIdentifier: pid_t
	let localizedName: String?
	let itemFrame: CGRect
}

/// `@unchecked Sendable` is safe because:
/// - The AXObserver callback dispatches to `@MainActor` via `DispatchQueue.main.async`.
/// - `subscribe()`/`unsubscribe()` run on the main run loop (called from `start()`/`stop()` and the health timer).
/// - `currentHovered` is only read from `EventTapController`'s main-run-loop callback.
/// - All access is serialized on the main thread.
final class DockObserver: @unchecked Sendable {
	private static let dockBundleID = "com.apple.dock"

	private var axObserver: AXObserver?
	private var dockPID: pid_t?
	private var subscribedList: AXUIElement?
	private var healthTimer: Timer?
	private var callbackContext: DockObserverCallbackContext?

	var onHoverChanged: (@Sendable (DockHoverInfo?) -> Void)?
	private(set) var currentHovered: DockHoverInfo?

	func start() {
		subscribe()
		healthTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
			self?.healthCheck()
		}
	}

	func stop() {
		unsubscribe()
		healthTimer?.invalidate()
		healthTimer = nil
	}

	private func healthCheck() {
		let current = NSRunningApplication.runningApplications(withBundleIdentifier: Self.dockBundleID).first
		if current?.processIdentifier != dockPID {
			unsubscribe()
			subscribe()
			return
		}
		if let list = subscribedList {
			var role: CFTypeRef?
			if AXUIElementCopyAttributeValue(list, kAXRoleAttribute as CFString, &role) != .success {
				unsubscribe()
				subscribe()
			}
		}
	}

	private func subscribe() {
		guard AXIsProcessTrusted() else {
			Log.info("dock observer: accessibility not trusted")
			return
		}
		guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: Self.dockBundleID).first
		else {
			return
		}

		let pid = dock.processIdentifier
		dockPID = pid
		let dockElement = AXUIElementCreateApplication(pid)

		guard
			let children = AXWindowAccessor.copyAttribute(
				kAXChildrenAttribute as CFString, from: dockElement) as? [AXUIElement],
			let list = children.first(where: {
				AXWindowAccessor.copyAttribute(kAXRoleAttribute as CFString, from: $0) as? String
					== kAXListRole
			})
		else {
			Log.info("dock observer: could not find AXList")
			return
		}

		var observer: AXObserver?
		guard AXObserverCreate(pid, dockSelectionChanged, &observer) == .success, let observer else {
			return
		}

		let contextBox = DockObserverCallbackContext(observer: self)
		let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(contextBox).toOpaque())
		guard
			AXObserverAddNotification(
				observer, list, kAXSelectedChildrenChangedNotification as CFString, context) == .success
		else {
			return
		}

		let runLoopSource = AXObserverGetRunLoopSource(observer)
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

		self.axObserver = observer
		self.callbackContext = contextBox
		subscribedList = list
		Log.info("dock observer: subscribed pid=%d", pid)
	}

	private func unsubscribe() {
		if let observer = axObserver {
			CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), .commonModes)
		}
		axObserver = nil
		callbackContext = nil
		dockPID = nil
		subscribedList = nil
	}

	@MainActor
	func handleSelectionChanged() {
		guard let list = subscribedList else { return }

		guard
			let selected = AXWindowAccessor.copyAttribute(
				kAXSelectedChildrenAttribute as CFString, from: list) as? [AXUIElement],
			let item = selected.first
		else {
			clearHover()
			return
		}

		guard
			let subrole = AXWindowAccessor.copyAttribute(kAXSubroleAttribute as CFString, from: item)
				as? String,
			subrole == "AXApplicationDockItem"
		else {
			clearHover()
			return
		}

		guard let url = AXWindowAccessor.copyAttribute(kAXURLAttribute as CFString, from: item) as? NSURL,
			let fileURL = url.absoluteURL,
			let bundle = Bundle(url: fileURL),
			let bundleID = bundle.bundleIdentifier
		else {
			clearHover()
			return
		}

		let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
		let app = running.first
		guard let position = AXWindowAccessor.pointAttribute(kAXPositionAttribute as CFString, from: item),
			let size = AXWindowAccessor.sizeAttribute(kAXSizeAttribute as CFString, from: item)
		else {
			clearHover()
			return
		}

		let info = DockHoverInfo(
			bundleIdentifier: bundleID,
			processIdentifier: app?.processIdentifier ?? 0,
			localizedName: app?.localizedName ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String,
			itemFrame: CGRect(origin: position, size: size)
		)
		currentHovered = info
		onHoverChanged?(info)
	}

	@MainActor
	private func clearHover() {
		guard currentHovered != nil else { return }
		currentHovered = nil
		onHoverChanged?(nil)
	}
}

private func dockSelectionChanged(
	_: AXObserver,
	_: AXUIElement,
	_: CFString,
	context: UnsafeMutableRawPointer?
) {
	guard let context else { return }
	let box = Unmanaged<DockObserverCallbackContext>.fromOpaque(context).takeUnretainedValue()
	DispatchQueue.main.async { [weak box] in
		box?.observer?.handleSelectionChanged()
	}
}

private final class DockObserverCallbackContext: @unchecked Sendable {
	weak var observer: DockObserver?

	init(observer: DockObserver) {
		self.observer = observer
	}
}
