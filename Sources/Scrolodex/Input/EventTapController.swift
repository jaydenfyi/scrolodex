import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import ScrolodexCore

/// `@unchecked Sendable` is safe because:
/// - The CGEvent tap callback fires on the main run loop (added to `CFRunLoopGetMain()`).
/// - `start()`/`stop()` are only called from `@MainActor` (via `AppDelegate`).
/// - Both execute on the main thread, so all mutations are serialized.
final class EventTapController: @unchecked Sendable {
	private let coordinator: NavigationCoordinator
	private let spaceSwitcher: SpaceSwitcher
	private let dockObserver: DockObserver?
	private let dockHoverConfigs: [DockHoverConfiguration]
	private let dockHandler: any DockActionHandling
	private let classifier: EventClassifier
	private var session: RouterSessionState
	private var eventTap: CFMachPort?
	private var runLoopSource: CFRunLoopSource?
	private let scrollThreshold: Double
	private var permissionCheck: () -> Bool

	init(
		coordinator: NavigationCoordinator, triggers: [TriggerHotkey],
		desktopTriggers: [DesktopSwitchTrigger] = [], 		desktopScrollThreshold: Double = ScrollSensitivity.default,
		spaceSwitcher: SpaceSwitcher = SpaceSwitcher(), dockObserver: DockObserver? = nil,
		dockHoverConfigs: [DockHoverConfiguration] = [],
		dockHandler: any DockActionHandling,
		permissionCheck: @escaping () -> Bool = { true }
	) {
		self.coordinator = coordinator
		self.spaceSwitcher = spaceSwitcher
		self.dockObserver = dockObserver
		self.dockHoverConfigs = dockHoverConfigs
		self.dockHandler = dockHandler
		self.scrollThreshold = desktopScrollThreshold
		self.permissionCheck = permissionCheck
		self.classifier = EventClassifier(
			triggers: triggers,
			desktopTriggers: desktopTriggers
		)
		self.session = RouterSessionState(desktopScrollThreshold: desktopScrollThreshold)
	}

	func stop() {
		if let eventTap {
			CGEvent.tapEnable(tap: eventTap, enable: false)
			CFMachPortInvalidate(eventTap)
		}
		if let runLoopSource {
			CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
		}
		eventTap = nil
		runLoopSource = nil
	}

	func start() {
		let mask = eventMask(EventTapPolicy.observedEventTypes)

		let refcon = Unmanaged.passUnretained(self).toOpaque()
		guard
			let tap = CGEvent.tapCreate(
				tap: .cgSessionEventTap,
				place: .tailAppendEventTap,
				options: .defaultTap,
				eventsOfInterest: mask,
				callback: eventTapCallback,
				userInfo: refcon
			)
		else {
			Log.info("failed to create event tap. Check Accessibility permissions")
			return
		}

		eventTap = tap
		runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
		if let runLoopSource {
			CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
		}
		CGEvent.tapEnable(tap: tap, enable: true)
		let names = classifier.triggers.map { "\($0.configuration.displayName)(\($0.hotkey.displayName))" }.joined(
			separator: ", ")
		let desktopCount = classifier.desktopTriggers.count
		Log.info("event tap started triggers=%@ desktopTriggers=%d", names, desktopCount)
	}

	fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
		let cursorLocation: CGPoint
		if type == .keyDown {
			cursorLocation = currentCursorLocation()
		} else {
			cursorLocation = event.location
		}

		let routerEvent = RouterEvent(
			type: type,
			flags: event.flags,
			keyCode: CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)),
			scrollDelta: event.getDoubleValueField(.scrollWheelEventDeltaAxis1),
			cursorLocation: cursorLocation,
			hasPermissions: permissionCheck()
		)

		let dockHoverInput = buildDockHoverInput(event: event)

		let (directive, action) = classifier.classify(
			event: routerEvent,
			dockHover: dockHoverInput,
			session: &session
		)

		switch directive {
		case .passThrough:
			return Unmanaged.passUnretained(event)
		case .consume:
			performAction(action)
			return nil
		case .consumeAndPassthrough:
			performAction(action)
			return Unmanaged.passUnretained(event)
		case .stopTap:
			performAction(action)
			stop()
			return Unmanaged.passUnretained(event)
		case .reenableTap:
			if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
			return Unmanaged.passUnretained(event)
		}
	}

	private func performAction(_ action: RouterAction) {
		switch action {
		case .none:
			break
		case .window(let windowAction):
			handleWindowAction(windowAction)
		case .desktop(let desktopAction):
			handleDesktopAction(desktopAction)
		case .dock(let dockAction):
			handleDockAction(dockAction)
		case .system(.permissionsLost):
			Task { @MainActor [coordinator] in coordinator.cancel() }
		}
	}

	private func handleWindowAction(_ action: WindowAction) {
		switch action {
		case .activateTrigger(let trigger, cursor: let cursor, preview: let preview):
			let context = TriggerContext.from(trigger: trigger, scrollThreshold: scrollThreshold)
			Task { @MainActor [coordinator] in
				if preview {
					coordinator.previewTrigger(
						context: context, cursor: cursor, hotkeyName: trigger.configuration.displayName)
				} else {
					coordinator.activate(context)
				}
			}
		case .scroll(let delta, let cursor):
			Task { @MainActor [coordinator] in
				coordinator.handleScroll(delta: delta, cursor: cursor)
			}
		case .clickConfirm:
			Log.debug("trigger click confirm")
			Task { @MainActor [coordinator] in coordinator.confirm() }
		case .triggerReleased:
			Task { @MainActor [coordinator] in coordinator.handleTriggerRelease() }
		case .keyboardNavigate(let direction, let trigger, let cursor):
			if let trigger {
				let context = TriggerContext.from(trigger: trigger, scrollThreshold: scrollThreshold)
				Task { @MainActor [coordinator] in
					coordinator.activate(context)
					coordinator.handleKeyboardNavigation(direction: direction, cursor: cursor)
				}
			} else {
				Task { @MainActor [coordinator] in
					coordinator.handleKeyboardNavigation(direction: direction, cursor: cursor)
				}
			}
		case .escapeCancel:
			Task { @MainActor [coordinator] in coordinator.cancel() }
		case .cursorMove(let cursor):
			Task { @MainActor [coordinator] in
				coordinator.handleCursorMove(cursor: cursor)
			}
		}
	}

	private func handleDesktopAction(_ action: DesktopAction) {
		switch action {
		case .activate(let trigger):
			spaceSwitcher.animateScroll = trigger.animateScroll
			spaceSwitcher.invertDirection = trigger.invertDirection
			spaceSwitcher.wrapAround = trigger.wrapAround
		case .switch(let direction, let trigger, let cursor):
			spaceSwitcher.animateScroll = trigger.animateScroll
			spaceSwitcher.invertDirection = trigger.invertDirection
			spaceSwitcher.wrapAround = trigger.wrapAround
			if let result = spaceSwitcher.switchDesktop(direction: direction, cursor: cursor) {
				Task { @MainActor [coordinator] in
					coordinator.showDesktopSwitch(result: result, cursor: cursor)
				}
			}
		case .cursorMove(let cursor):
			Task { @MainActor [coordinator] in
				coordinator.handleDesktopCursorMove(cursor: cursor)
			}
		case .released:
			Task { @MainActor [coordinator] in
				coordinator.handleDesktopTriggerRelease()
			}
		}
	}

	private func handleDockAction(_ action: DockAction) {
		Task { @MainActor [dockHandler] in
			dockHandler.handle(dockAction: action)
		}
	}

	private func buildDockHoverInput(event: CGEvent) -> DockHoverInput {
		guard let dockObserver else { return DockHoverInput() }
		guard let hovered = dockObserver.currentHovered else {
			return DockHoverInput(configs: dockHoverConfigs)
		}
		return DockHoverInput(
			configs: dockHoverConfigs,
			hoveredBundleID: hovered.bundleIdentifier,
			hoveredItemFrame: hovered.itemFrame,
			anchorPoint: DockGeometry.anchorPoint(forDockItemFrame: hovered.itemFrame),
			ownBundleID: Bundle.main.bundleIdentifier ?? ""
		)
	}

	private func eventMask(_ types: [CGEventType]) -> CGEventMask {
		types.reduce(CGEventMask(0)) { mask, type in
			mask | CGEventMask(1 << type.rawValue)
		}
	}
}

private func currentCursorLocation() -> CGPoint {
	let mainScreenHeight = NSScreen.screens[0].frame.height
	let appKitLocation = NSEvent.mouseLocation
	return CGPoint(x: appKitLocation.x, y: mainScreenHeight - appKitLocation.y)
}

private let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
	guard let userInfo else { return Unmanaged.passUnretained(event) }
	let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
	return controller.handle(type: type, event: event)
}
