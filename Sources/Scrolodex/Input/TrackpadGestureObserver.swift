import AppKit
import CoreGraphics
import Foundation
import ScrolodexCore

/// `@unchecked Sendable` is safe because:
/// - The HID event tap callback fires on the main run loop (added to `CFRunLoopGetMain()`).
/// - `start()`/`stop()` are only called from `@MainActor` (via `AppDelegate`).
/// - Both execute on the main thread, so all mutations are serialized.
final class TrackpadGestureObserver: @unchecked Sendable {
	private let coordinator: NavigationCoordinator
	private(set) var eventTap: CFMachPort?
	private var runLoopSource: CFRunLoopSource?
	private var gestureTracker = GestureTouchTracker()
	private var configs: [GestureTriggerConfig] = []
	private var activeTriggerConfig: GestureTriggerConfig?
	private var triggerActive = false
	private var nonGestureDetected = false
	private var swipeIntent: GestureSwipeIntent = .undecided
	private var pendingEmptySnapshotRelease: Task<Void, Never>?
	private var pendingEventTapRestart: Task<Void, Never>?
	private var pendingEventTapHealthCheck: Task<Void, Never>?
	private var cursorLock = GestureCursorLockState()
	private let scrollThreshold: Double
	private let dockObserver: DockObserver?
	private let dockHoverConfigs: [DockHoverConfiguration]
	private let dockHandler: any DockActionHandling
	private let cursorTrackingState: WindowCursorTrackingState

	init(
		coordinator: NavigationCoordinator,
		scrollThreshold: Double = ScrollSensitivity.default,
		dockObserver: DockObserver? = nil,
		dockHoverConfigs: [DockHoverConfiguration] = [],
		dockHandler: any DockActionHandling,
		cursorTrackingState: WindowCursorTrackingState = WindowCursorTrackingState()
	) {
		self.coordinator = coordinator
		self.scrollThreshold = scrollThreshold
		self.dockObserver = dockObserver
		self.dockHoverConfigs = dockHoverConfigs
		self.dockHandler = dockHandler
		self.cursorTrackingState = cursorTrackingState
	}

	deinit {
		stop()
	}

	func start(triggerConfigs: [GestureTriggerConfig]) {
		stop()
		guard !triggerConfigs.isEmpty else { return }
		configs = triggerConfigs
		createEventTap(triggerConfigs: triggerConfigs)
	}

	private func createEventTap(triggerConfigs: [GestureTriggerConfig]) {
		let mask = Self.observedEventTypes.reduce(CGEventMask(0)) { mask, eventType in
			mask | CGEventMask(1 << UInt64(eventType.rawValue))
		}
		let refcon = Unmanaged.passUnretained(self).toOpaque()
		guard
			let tap = CGEvent.tapCreate(
				tap: .cghidEventTap,
				place: .headInsertEventTap,
				options: .defaultTap,
				eventsOfInterest: mask,
				callback: { _, type, event, userInfo in
					guard let userInfo else { return Unmanaged.passUnretained(event) }
					let observer = Unmanaged<TrackpadGestureObserver>.fromOpaque(userInfo)
						.takeUnretainedValue()
					if EventTapPolicy.isDisabledEvent(type) {
						observer.releaseGesture()
						let reason = type == .tapDisabledByTimeout ? "timeout" : "userInput"
						observer.recoverEventTapAfterDisable(reason: reason)
						return Unmanaged.passUnretained(event)
					}
					return observer.handle(type: type, cgEvent: event)
				},
				userInfo: refcon
			)
		else {
			Log.info("failed to create gesture event tap; scheduling retry")
			scheduleEventTapRestart(reason: "createFailed")
			return
		}

		eventTap = tap
		guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
			Log.info("failed to create gesture event tap run loop source; scheduling retry")
			CFMachPortInvalidate(tap)
			eventTap = nil
			scheduleEventTapRestart(reason: "runLoopSourceFailed")
			return
		}
		runLoopSource = source
		CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
		CGEvent.tapEnable(tap: tap, enable: true)
		let configSummary = triggerConfigs.map(\.fingerCount.displayName).joined(separator: ", ")
		Log.info("gesture observer started configs=%@", configSummary as NSString)
	}

	func stop() {
		if let eventTap {
			CGEvent.tapEnable(tap: eventTap, enable: false)
			CFMachPortInvalidate(eventTap)
		}
		if let runLoopSource {
			CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
		}
		pendingEventTapRestart?.cancel()
		pendingEventTapRestart = nil
		pendingEventTapHealthCheck?.cancel()
		pendingEventTapHealthCheck = nil
		eventTap = nil
		runLoopSource = nil
		cursorTrackingState.isActive = false
		releaseCursorLock()
		pendingEmptySnapshotRelease?.cancel()
		pendingEmptySnapshotRelease = nil
		gestureTracker.reset()
		activeTriggerConfig = nil
		triggerActive = false
		nonGestureDetected = false
		swipeIntent = .undecided
	}

	private func recoverEventTapAfterDisable(reason: String) {
		guard let eventTap else {
			Log.info(
				"gesture event tap disabled reason=%@ without active tap; scheduling retry",
				reason as NSString)
			scheduleEventTapRestart(reason: reason)
			return
		}

		Log.info("gesture event tap disabled reason=%@; re-enabling", reason as NSString)
		CGEvent.tapEnable(tap: eventTap, enable: true)
		scheduleEventTapHealthCheck(reason: reason)
	}

	private func scheduleEventTapRestart(reason: String) {
		guard pendingEventTapRestart == nil, !configs.isEmpty else { return }
		let triggerConfigs = configs
		pendingEventTapRestart = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			guard !Task.isCancelled else { return }
			guard let self else { return }
			self.pendingEventTapRestart = nil
			if let eventTap = self.eventTap, CGEvent.tapIsEnabled(tap: eventTap) { return }
			Log.info("retrying gesture event tap start reason=%@", reason as NSString)
			self.start(triggerConfigs: triggerConfigs)
		}
	}

	private func scheduleEventTapHealthCheck(reason: String) {
		guard pendingEventTapHealthCheck == nil else { return }
		pendingEventTapHealthCheck = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: 500_000_000)
			guard !Task.isCancelled else { return }
			guard let self else { return }
			self.pendingEventTapHealthCheck = nil
			guard let eventTap = self.eventTap else {
				self.scheduleEventTapRestart(reason: reason)
				return
			}
			guard !CGEvent.tapIsEnabled(tap: eventTap) else { return }
			Log.info("gesture event tap still disabled reason=%@; re-enabling", reason as NSString)
			CGEvent.tapEnable(tap: eventTap, enable: true)
		}
	}

	fileprivate func handle(type: CGEventType, cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
		if type == .mouseMoved {
			if cursorLock.isFrozen {
				restoreLockedCursorPosition()
				return nil
			}
			cursorLock.refresh(to: cgCursorLocation())
			return Unmanaged.passUnretained(cgEvent)
		}

		guard let nsEvent = NSEvent(cgEvent: cgEvent) else {
			return Unmanaged.passUnretained(cgEvent)
		}
		let touches = nsEvent.allTouches()
		let gestureTouches = touches.map(GestureTouch.init)
		if gestureTouches.isEmpty {
			if triggerActive, gestureTracker.hasDownTouches {
				scheduleEmptySnapshotRelease()
				return Unmanaged.passUnretained(cgEvent)
			}
			releaseGesture()
			return Unmanaged.passUnretained(cgEvent)
		}
		pendingEmptySnapshotRelease?.cancel()
		pendingEmptySnapshotRelease = nil
		gestureTracker.updateDownTouches(gestureTouches)

		let activeTouches = gestureTouches.filter(\.isDown)
		if !gestureTracker.hasDownTouches {
			releaseGesture()
			return Unmanaged.passUnretained(cgEvent)
		}

		if !triggerActive {
			let minimumRequired = configs.map(\.fingerCount.rawValue).min() ?? 2
			if gestureTracker.resetInactiveSnapshotIfBelowMinimumFingerCount(
				gestureTouches,
				minimumFingerCount: minimumRequired)
			{
				Log.debug(
					"gesture inactive reset: active=%d down=%d min=%d",
					activeTouches.count, gestureTracker.downTouchCount, minimumRequired)
				nonGestureDetected = false
				swipeIntent = .undecided
				activeTriggerConfig = nil
				releaseCursorLock()
				return Unmanaged.passUnretained(cgEvent)
			}
		}

		if activeTouches.count < 2 {
			unfreezeCursor()
			return Unmanaged.passUnretained(cgEvent)
		}

		if !triggerActive, !nonGestureDetected {
			let maxRequired = configs.map(\.fingerCount.rawValue).max() ?? 0
			if activeTouches.count > maxRequired, gestureTracker.hasRecordedStart() {
				let delta = gestureTracker.swipeDelta(activeTouches)
				if abs(delta.dx) > 0.015 || abs(delta.dy) > 0.015 {
					nonGestureDetected = true
					releaseCursorLock()
				}
			}
		}

		if nonGestureDetected {
			return Unmanaged.passUnretained(cgEvent)
		}

		if !triggerActive {
			for config in configs {
				if activeTouches.count == config.fingerCount.rawValue {
					let threshold: CGFloat = 0.03
					let dominanceRatio: CGFloat = 1.5
					let isNew = gestureTracker.recordStart(activeTouches)
					if isNew {
						activeTriggerConfig = config
						swipeIntent = .undecided
						beginCursorLock()
					} else if activeTriggerConfig == nil {
						Log.debug(
							"gesture activation blocked: stale identities=%@",
							gestureTracker.trackedIdentities as NSObject)
						return Unmanaged.passUnretained(cgEvent)
					}

					let delta = gestureTracker.swipeDelta(activeTouches)
					let result = config.swipeDirection.navigationDelta(
						dx: delta.dx,
						dy: delta.dy,
						threshold: threshold,
						dominanceRatio: dominanceRatio,
						currentIntent: swipeIntent)
					swipeIntent = result.intent

					if let navigation = result.navigation {
						triggerActive = true
						freezeCursor()
						let captured = config
						let scrollThreshold = scrollThreshold
						let direction = navigation.direction * (config.invertDirection ? -1 : 1)
						let cursor = cursorLock.anchor ?? cgCursorLocation()
						let resolvedDockAction = resolveDockAction(cursor: cursor)
						cursorTrackingState.isActive = resolvedDockAction == nil
						Task { @MainActor [coordinator, dockHandler] in
							if let resolvedDockAction {
								dockHandler.handle(dockAction: resolvedDockAction)
							} else {
								let context = TriggerContext.from(
									gestureConfig: captured,
									scrollThreshold: scrollThreshold)
								coordinator.activate(context)
								coordinator.handleKeyboardNavigation(
									direction: direction, cursor: cursor)
							}
						}
						gestureTracker.resetAxis(
							activeTouches, horizontal: navigation.axis == .horizontal)
						return nil
					}
					return Unmanaged.passUnretained(cgEvent)
				}
			}
		}

		if triggerActive {
			if let activeTriggerConfig,
				GestureTouchSnapshot.exceedsFingerCount(
					gestureTouches,
					configuredFingerCount: activeTriggerConfig.fingerCount.rawValue)
			{
				cancelGesture()
				return Unmanaged.passUnretained(cgEvent)
			}

			let delta = gestureTracker.swipeDelta(activeTouches)
			let threshold: CGFloat = 0.03
			let dominanceRatio: CGFloat = 1.5
			let invert = activeTriggerConfig?.invertDirection == true ? -1 : 1
			let result = activeTriggerConfig?.swipeDirection.navigationDelta(
				dx: delta.dx,
				dy: delta.dy,
				threshold: threshold,
				dominanceRatio: dominanceRatio,
				currentIntent: swipeIntent)
			if let result {
				swipeIntent = result.intent
			}

			if let navigation = result?.navigation {
				let direction = navigation.direction * invert
				gestureTracker.resetAxis(activeTouches, horizontal: navigation.axis == .horizontal)
				let cursor = cursorLock.anchor ?? cgCursorLocation()
				Task { @MainActor [coordinator] in
					coordinator.handleKeyboardNavigation(direction: direction, cursor: cursor)
				}
			}
			freezeCursor()
			return nil
		}

		return Unmanaged.passUnretained(cgEvent)
	}

	private func resolveDockAction(cursor: CGPoint) -> DockAction? {
		guard let dockObserver,
			let hovered = dockObserver.currentHovered,
			hovered.bundleIdentifier != (Bundle.main.bundleIdentifier ?? ""),
			hovered.itemFrame.contains(cursor),
			let dockConfig = dockHoverConfigs.first(where: { $0.enabled })
		else { return nil }

		return .activate(config: dockConfig, bundleID: hovered.bundleIdentifier)
	}

	private enum GestureEndAction {
		case release
		case cancel
	}

	private func beginCursorLock() {
		_ = cursorLock.lock(at: cgCursorLocation())
	}

	private func freezeCursor() {
		guard !cursorLock.isFrozen else { return }
		cursorLock.freeze()
		_ = CGAssociateMouseAndMouseCursorPosition(0)
		restoreLockedCursorPosition()
	}

	private func unfreezeCursor() {
		guard cursorLock.isFrozen else { return }
		cursorLock.unfreeze()
		_ = CGAssociateMouseAndMouseCursorPosition(1)
	}

	private func restoreLockedCursorPosition() {
		guard let anchor = cursorLock.anchor else { return }
		_ = CGWarpMouseCursorPosition(anchor)
	}

	private func releaseCursorLock() {
		if cursorLock.isFrozen { _ = CGAssociateMouseAndMouseCursorPosition(1) }
		restoreLockedCursorPosition()
		cursorLock.release()
	}

	private func endGesture(_ action: GestureEndAction) {
		pendingEmptySnapshotRelease?.cancel()
		pendingEmptySnapshotRelease = nil
		releaseCursorLock()
		if triggerActive {
			triggerActive = false
			cursorTrackingState.isActive = false
			Task { @MainActor [coordinator] in
				switch action {
				case .release: coordinator.handleTriggerRelease()
				case .cancel: coordinator.cancel()
				}
			}
		}
		gestureTracker.reset()
		activeTriggerConfig = nil
		nonGestureDetected = false
		swipeIntent = .undecided
	}

	private func releaseGesture() { endGesture(.release) }

	private func cancelGesture() { endGesture(.cancel) }

	private func scheduleEmptySnapshotRelease() {
		guard pendingEmptySnapshotRelease == nil else { return }
		pendingEmptySnapshotRelease = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: 80_000_000)
			guard !Task.isCancelled else { return }
			self?.releaseGesture()
		}
	}

	private static let observedEventTypes: [NSEvent.EventType] = [
		.mouseMoved,
		.beginGesture,
		.gesture,
		.swipe,
		.endGesture,
	]
}

private extension GestureTouch {
	init(_ touch: NSTouch) {
		self.init(
			identity: "\(touch.identity)",
			phase: GestureTouchPhase(touch.phase),
			normalizedPosition: touch.normalizedPosition,
			isResting: touch.isResting)
	}
}

private extension GestureTouchPhase {
	init(_ phase: NSTouch.Phase) {
		switch phase {
		case .began:
			self = .began
		case .moved:
			self = .moved
		case .stationary:
			self = .stationary
		case .ended:
			self = .ended
		case .cancelled:
			self = .cancelled
		default:
			self = .cancelled
		}
	}
}
