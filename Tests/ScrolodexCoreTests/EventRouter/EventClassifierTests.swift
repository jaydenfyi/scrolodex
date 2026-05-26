import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Event classifier")
struct EventClassifierTests {
	private func makeTrigger(
		flags: CGEventFlags = .maskControl,
		scope: TriggerScope = .underCursor,
		filter: TriggerFilter = .allApps,
		showOnPress: Bool = true,
		keyboardNavigation: KeyboardNavigationBinding = KeyboardNavigationBinding()
	) -> TriggerHotkey {
		TriggerHotkey(
			configuration: TriggerConfiguration(scope: scope, filter: filter),
			hotkey: HotkeyConfiguration(flags: flags),
			overlayMode: .default,
			peekEnabled: true,
			peekOpacity: 0.94,
			theme: .default,
			monitorScope: .currentMonitor,
			showOnPress: showOnPress,
			invertDirection: false,
			animate: true,
			wrapAround: true,
			keyboardNavigation: keyboardNavigation
		)
	}

	private func makeDesktopTrigger(
		flags: CGEventFlags = .maskAlternate,
		keyboardNavigation: KeyboardNavigationBinding = KeyboardNavigationBinding()
	) -> DesktopSwitchTrigger {
		DesktopSwitchTrigger(
			hotkey: HotkeyConfiguration(flags: flags),
			invertDirection: false,
			animateScroll: true,
			wrapAround: true,
			keyboardNavigation: keyboardNavigation
		)
	}

	private func makeDockInput(
		bundleID: String = "com.example.app",
		frame: CGRect = CGRect(x: 100, y: 800, width: 60, height: 60),
		anchor: CGPoint = CGPoint(x: 130, y: 830),
		ownBundleID: String = "com.scrolodex.app",
		config: DockHoverConfiguration = DockHoverConfiguration()
	) -> DockHoverInput {
		DockHoverInput(
			configs: [config],
			hoveredBundleID: bundleID,
			hoveredItemFrame: frame,
			anchorPoint: anchor,
			ownBundleID: ownBundleID
		)
	}

	// MARK: - Tap state

	@Test("tap disabled by timeout with permissions returns reenableTap")
	func tapDisabledByTimeoutWithPermissions() {
		let classifier = EventClassifier(triggers: [makeTrigger()], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .tapDisabledByTimeout, flags: [], keyCode: 0, hasPermissions: true)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .reenableTap)
		#expect(action == .none)
	}

	@Test("tap disabled by user input with permissions returns reenableTap")
	func tapDisabledByUserInputWithPermissions() {
		let classifier = EventClassifier(triggers: [makeTrigger()], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .tapDisabledByUserInput, flags: [], keyCode: 0, hasPermissions: true)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .reenableTap)
		#expect(action == .none)
	}

	@Test("tap disabled without permissions clears active triggers and returns stopTap")
	func tapDisabledWithoutPermissions() {
		let trigger = makeTrigger()
		let desktopTrigger = makeDesktopTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [desktopTrigger])
		var session = RouterSessionState(
			activeTrigger: trigger,
			activeDesktopTrigger: desktopTrigger
		)
		let event = RouterEvent(type: .tapDisabledByTimeout, flags: [], keyCode: 0, hasPermissions: false)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .stopTap)
		#expect(action == .system(.permissionsLost))
		#expect(session.activeTrigger == nil)
		#expect(session.activeDesktopTrigger == nil)
	}

	// MARK: - Permission guard

	@Test("event without permissions and active triggers returns stopTap + permissionsLost")
	func eventWithoutPermissionsClearsState() {
		let trigger = makeTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .scrollWheel, flags: trigger.hotkey.flags, keyCode: 0, hasPermissions: false)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .stopTap)
		#expect(action == .system(.permissionsLost))
		#expect(session.activeTrigger == nil)
	}

	@Test("event without permissions and no active triggers passes through")
	func eventWithoutPermissionsNoActiveState() {
		let classifier = EventClassifier(triggers: [makeTrigger()], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .scrollWheel, flags: .maskControl, keyCode: 0, hasPermissions: false)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .passThrough)
		#expect(action == .none)
	}

	// MARK: - Escape cancel

	@Test("escape cancels active window trigger")
	func escapeCancelsActiveTrigger() {
		let trigger = makeTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .keyDown, flags: [], keyCode: 53)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		#expect(action == .window(.escapeCancel))
		#expect(session.activeTrigger == nil)
	}

	@Test("escape without active trigger passes through")
	func escapeWithoutActiveTrigger() {
		let classifier = EventClassifier(triggers: [makeTrigger()], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .keyDown, flags: [], keyCode: 53)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .passThrough)
		#expect(action == .none)
	}

	@Test("non-escape keyDown is not escape cancel")
	func nonEscapeKeyDownIsNotCancel() {
		let trigger = makeTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .keyDown, flags: [], keyCode: 40)
		let (directive, _) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .passThrough)
	}

	// MARK: - Window trigger routing

	@Test("trigger press activates and previews")
	func triggerPressActivatesAndPreviews() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .flagsChanged, flags: .maskControl, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		if case .window(.activateTrigger(let matched, cursor: let cursor, preview: let preview)) = action {
			#expect(matched == trigger)
			#expect(cursor == CGPoint(x: 100, y: 200))
			#expect(preview == true)
		} else {
			Issue.record("expected activateTrigger, got \(action)")
		}
		#expect(session.activeTrigger == trigger)
	}

	@Test("trigger scroll while held produces scroll action")
	func triggerScrollWhileHeld() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .scrollWheel, flags: .maskControl, keyCode: 0, scrollDelta: -3.0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		if case .window(.scroll(let delta, let cursor)) = action {
			#expect(delta == -3.0)
			#expect(cursor == CGPoint(x: 100, y: 200))
		} else {
			Issue.record("expected scroll, got \(action)")
		}
	}

	@Test("trigger click confirm while held")
	func triggerClickConfirmWhileHeld() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .leftMouseDown, flags: .maskControl, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .window(.clickConfirm))
	}

	@Test("trigger release produces triggerReleased and clears active trigger")
	func triggerRelease() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .flagsChanged, flags: [], keyCode: 0)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .window(.triggerReleased))
		#expect(session.activeTrigger == nil)
	}

	@Test("scroll without trigger held passes through")
	func scrollWithoutTriggerPassesThrough() {
		let classifier = EventClassifier(triggers: [makeTrigger(flags: .maskControl)], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .scrollWheel, flags: [], keyCode: 0, scrollDelta: -3.0)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .passThrough)
		#expect(action == .none)
	}

	@Test("keyboard navigation activates matching trigger")
	func keyboardNavigationActivatesTrigger() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskControl, keyCode: 49)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeTrigger(keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .keyDown, flags: .maskControl, keyCode: 49, cursorLocation: CGPoint(x: 50, y: 50))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		if case .window(.keyboardNavigate(direction: let direction, trigger: let matchedTrigger, cursor: let cursor)) = action {
			#expect(direction == 1)
			#expect(matchedTrigger == trigger)
			#expect(cursor == CGPoint(x: 50, y: 50))
		} else {
			Issue.record("expected keyboardNavigate, got \(action)")
		}
		#expect(session.activeTrigger == trigger)
	}

	@Test("keyboard navigation with active trigger uses active trigger bindings")
	func keyboardNavigationWithActiveTrigger() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskControl, keyCode: 49)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeTrigger(keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .keyDown, flags: .maskControl, keyCode: 49, cursorLocation: CGPoint(x: 50, y: 50))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		if case .window(.keyboardNavigate(direction: let direction, trigger: let matchedTrigger, cursor: _)) = action {
			#expect(direction == 1)
			#expect(matchedTrigger == trigger)
		} else {
			Issue.record("expected keyboardNavigate, got \(action)")
		}
	}

	@Test("keyboard navigation consumes matched key input")
	func keyboardNavigationConsumesMatchedKeyInput() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskAlternate, keyCode: 50)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeTrigger(flags: .maskAlternate, keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .keyDown, flags: .maskAlternate, keyCode: 50, cursorLocation: CGPoint(x: 50, y: 50))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)

		#expect(directive == .consume)
		if case .window(.keyboardNavigate) = action {
		} else {
			Issue.record("expected keyboardNavigate, got \(action)")
		}
	}

	@Test("escape keyboard navigation takes priority over active trigger cancel")
	func escapeKeyboardNavigationTakesPriorityOverActiveTriggerCancel() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskAlternate, keyCode: 53)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeTrigger(flags: .maskAlternate, keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .keyDown, flags: .maskAlternate, keyCode: 53, cursorLocation: CGPoint(x: 50, y: 50))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)

		#expect(directive == .consume)
		if case .window(.keyboardNavigate(direction: let direction, trigger: let matchedTrigger, cursor: _)) = action {
			#expect(direction == 1)
			#expect(matchedTrigger == trigger)
		} else {
			Issue.record("expected keyboardNavigate, got \(action)")
		}
		#expect(session.activeTrigger == trigger)
	}

	@Test("trigger press without showOnPress activates but does not preview")
	func triggerPressWithoutShowOnPress() {
		let trigger = makeTrigger(showOnPress: false)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .flagsChanged, flags: .maskControl, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		if case .window(.activateTrigger(_, cursor: _, preview: let preview)) = action {
			#expect(preview == false)
		} else {
			Issue.record("expected activateTrigger, got \(action)")
		}
	}

	@Test("same trigger held continues without re-activating")
	func sameTriggerHeldContinues() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .flagsChanged, flags: .maskControl, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .none)
	}

	// MARK: - Desktop trigger routing

	@Test("desktop trigger press activates desktop trigger")
	func desktopTriggerPress() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState()
		let event = RouterEvent(type: .flagsChanged, flags: .maskAlternate, keyCode: 0)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .desktop(.activate(trigger)))
		#expect(session.activeDesktopTrigger == trigger)
	}

	@Test("desktop trigger scroll while held produces desktopSwitch when threshold exceeded")
	func desktopTriggerScrollWhileHeld() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState(activeDesktopTrigger: trigger, desktopScrollThreshold: 6)
		let event = RouterEvent(type: .scrollWheel, flags: .maskAlternate, keyCode: 0, scrollDelta: 10.0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		if case .desktop(.switch(let direction, trigger: let matchedTrigger, cursor: let cursor)) = action {
			#expect(direction == .right)
			#expect(matchedTrigger == trigger)
			#expect(cursor == CGPoint(x: 100, y: 200))
		} else {
			Issue.record("expected desktopSwitch, got \(action)")
		}
	}

	@Test("desktop trigger scroll below threshold produces no switch")
	func desktopTriggerScrollBelowThreshold() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState(activeDesktopTrigger: trigger, desktopScrollThreshold: 6)
		let event = RouterEvent(type: .scrollWheel, flags: .maskAlternate, keyCode: 0, scrollDelta: 1.0, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		#expect(action == .none)
	}

	@Test("desktop trigger release clears desktop trigger and resets accumulator")
	func desktopTriggerRelease() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState(activeDesktopTrigger: trigger, desktopScrollThreshold: 6)
		let event = RouterEvent(type: .flagsChanged, flags: [], keyCode: 0)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .desktop(.released))
		#expect(session.activeDesktopTrigger == nil)
	}

	@Test("desktop left mouse down while held is consumed")
	func desktopLeftMouseDownConsumed() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState()
		let event = RouterEvent(type: .leftMouseDown, flags: .maskAlternate, keyCode: 0)
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .none)
	}

	@Test("desktop keyboard shortcut produces desktopSwitch")
	func desktopKeyboardShortcut() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskAlternate, keyCode: 49)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeDesktopTrigger(keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState()
		let event = RouterEvent(type: .keyDown, flags: .maskAlternate, keyCode: 49, cursorLocation: CGPoint(x: 100, y: 200))
		let (directive, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consume)
		if case .desktop(.switch(let direction, trigger: let matchedTrigger, cursor: let cursor)) = action {
			#expect(direction == .right)
			#expect(matchedTrigger == trigger)
			#expect(cursor == CGPoint(x: 100, y: 200))
		} else {
			Issue.record("expected desktopSwitch, got \(action)")
		}
		#expect(session.activeDesktopTrigger == trigger)
	}

	@Test("desktop keyboard shortcut backward direction")
	func desktopKeyboardShortcutBackward() {
		let backward = KeyboardHotkeyConfiguration(flags: .maskAlternate, keyCode: 50)
		let binding = KeyboardNavigationBinding(enabled: true, forward: nil, backward: backward)
		let trigger = makeDesktopTrigger(keyboardNavigation: binding)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState()
		let event = RouterEvent(type: .keyDown, flags: .maskAlternate, keyCode: 50, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		if case .desktop(.switch(let direction, trigger: _, cursor: _)) = action {
			#expect(direction == .left)
		} else {
			Issue.record("expected desktopSwitch, got \(action)")
		}
	}

	@Test("desktop trigger scroll via activeDesktopTrigger after partial flags release")
	func desktopScrollViaActiveAfterPartialRelease() {
		let trigger = makeDesktopTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [trigger])
		var session = RouterSessionState(activeDesktopTrigger: trigger, desktopScrollThreshold: 6)
		let event = RouterEvent(type: .scrollWheel, flags: [], keyCode: 0, scrollDelta: 10.0, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		if case .desktop(.switch(let direction, trigger: _, cursor: _)) = action {
			#expect(direction == .right)
		} else {
			Issue.record("expected desktopSwitch via activeDesktopTrigger, got \(action)")
		}
	}

	@Test("desktop trigger takes priority over window trigger")
	func desktopTriggerPriorityOverWindowTrigger() {
		let windowTrigger = makeTrigger(flags: .maskControl)
		let desktopTrigger = makeDesktopTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [windowTrigger], desktopTriggers: [desktopTrigger])
		var session = RouterSessionState()
		let event = RouterEvent(type: .flagsChanged, flags: .maskControl, keyCode: 0)
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(action == .desktop(.activate(desktopTrigger)))
		#expect(session.activeDesktopTrigger == desktopTrigger)
		#expect(session.activeTrigger == nil)
	}

	// MARK: - Dock hover routing

	@Test("dock hover scroll activates dock session and produces dockScroll")
	func dockHoverScrollActivatesSession() {
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue)
		let trigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .scrollWheel, flags: .maskAlternate, keyCode: 0, scrollDelta: -3.0, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)
		#expect(directive == .consume)
		#expect(session.dockSessionActive == true)
		if case .dock(.scroll(delta: let delta, config: _, anchor: let anchor, bundleID: let bundleID)) = action {
			#expect(delta == -3.0)
			#expect(anchor == CGPoint(x: 130, y: 830))
			#expect(bundleID == "com.example.app")
		} else {
			Issue.record("expected dockScroll, got \(action)")
		}
	}

	@Test("dock hover preview activates dock session")
	func dockHoverPreview() {
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue, showOnPress: true)
		let trigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .flagsChanged, flags: .maskAlternate, keyCode: 0, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(session.dockSessionActive == true)
		if case .dock(.preview(config: _, anchor: let anchor, bundleID: let bundleID)) = action {
			#expect(anchor == CGPoint(x: 130, y: 830))
			#expect(bundleID == "com.example.app")
		} else {
			Issue.record("expected dockPreview, got \(action)")
		}
	}

	@Test("dock hover release falls through to general triggerReleased")
	func dockHoverRelease() {
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue)
		let trigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(
			activeTrigger: trigger,
			dockSessionActive: true
		)
		let event = RouterEvent(type: .flagsChanged, flags: [], keyCode: 0)
		let dockInput = DockHoverInput(configs: [config])
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)
		#expect(directive == .consumeAndPassthrough)
		#expect(action == .window(.triggerReleased))
		#expect(session.activeTrigger == nil)
	}

	@Test("dock hover ignores own bundle ID — falls through to window trigger")
	func dockHoverIgnoresOwnBundleID() {
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue)
		let trigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState()
		let dockInput = makeDockInput(bundleID: "com.scrolodex.app", config: config)
		let event = RouterEvent(type: .scrollWheel, flags: .maskAlternate, keyCode: 0, scrollDelta: -3.0, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)
		#expect(directive == .consume)
		if case .window(.scroll) = action {
		} else {
			Issue.record("expected scroll from window trigger fallback, got \(action)")
		}
	}

	@Test("dock hover ignores cursor not over dock item — falls through to window trigger")
	func dockHoverIgnoresCursorNotOverItem() {
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue)
		let trigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .scrollWheel, flags: .maskAlternate, keyCode: 0, scrollDelta: -3.0, cursorLocation: CGPoint(x: 0, y: 0))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)
		#expect(directive == .consume)
		if case .window(.scroll) = action {
		} else {
			Issue.record("expected scroll from window trigger fallback, got \(action)")
		}
	}

	@Test("dock hover keyboard navigate produces dockScroll action with direction")
	func dockHoverKeyboardNavigate() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskControl, keyCode: 50)
		let kbBinding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskControl.rawValue, keyboardNavigation: kbBinding)
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(dockSessionActive: true)
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .keyDown, flags: .maskControl, keyCode: 50, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)

		#expect(directive == .consume)
		if case .dock(.keyboardNavigate(direction: let direction, config: _, anchor: let anchor, bundleID: let bundleID)) = action {
			#expect(direction == 1)
			#expect(anchor == CGPoint(x: 130, y: 830))
			#expect(bundleID == "com.example.app")
		} else {
			Issue.record("expected dockKeyboardNavigate, got \(action)")
		}
		#expect(session.dockSessionActive == true)
	}

	@Test("dock hover keyboard navigate without matched trigger still navigates")
	func dockHoverKeyboardNavigateNoTrigger() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskControl, keyCode: 50)
		let kbBinding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskControl.rawValue, keyboardNavigation: kbBinding)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [])
		var session = RouterSessionState(dockSessionActive: true)
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .keyDown, flags: .maskControl, keyCode: 50, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)

		#expect(directive == .consume)
		if case .dock(.keyboardNavigate(direction: let direction, config: _, anchor: _, bundleID: _)) = action {
			#expect(direction == 1)
		} else {
			Issue.record("expected dockKeyboardNavigate, got \(action)")
		}
	}

	@Test("dock hover keyboard navigate uses keyboard binding even when dock modifier differs")
	func dockHoverKeyboardNavigateWithDifferentModifier() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskCommand, keyCode: 50)
		let kbBinding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let config = DockHoverConfiguration(enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue, keyboardNavigation: kbBinding)
		let classifier = EventClassifier(triggers: [], desktopTriggers: [])
		var session = RouterSessionState()
		let dockInput = makeDockInput(config: config)
		let event = RouterEvent(type: .keyDown, flags: .maskCommand, keyCode: 50, cursorLocation: CGPoint(x: 130, y: 830))
		let (directive, action) = classifier.classify(event: event, dockHover: dockInput, session: &session)

		#expect(directive == .consume)
		if case .dock(.keyboardNavigate(direction: let direction, config: _, anchor: _, bundleID: let bundleID)) = action {
			#expect(direction == 1)
			#expect(bundleID == "com.example.app")
		} else {
			Issue.record("expected dockKeyboardNavigate, got \(action)")
		}
	}

	// MARK: - Edge cases

	@Test("non-keyDown event with escape keyCode is not cancel")
	func nonKeyDownEscapeIsNotCancel() {
		let trigger = makeTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .flagsChanged, flags: [], keyCode: 53)
		let (directive, _) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(directive == .consumeAndPassthrough)
	}

	@Test("desktop keyboard shortcut takes priority over escape cancel")
	func desktopKeyShortcutPriorityOverEscape() {
		let forward = KeyboardHotkeyConfiguration(flags: .maskAlternate, keyCode: 53)
		let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: nil)
		let trigger = makeDesktopTrigger(keyboardNavigation: binding)
		let windowTrigger = makeTrigger(flags: .maskAlternate)
		let classifier = EventClassifier(triggers: [windowTrigger], desktopTriggers: [trigger])
		var session = RouterSessionState(activeTrigger: windowTrigger)
		let event = RouterEvent(type: .keyDown, flags: .maskAlternate, keyCode: 53, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		if case .desktop(.switch) = action {
		} else {
			Issue.record("expected desktopSwitch, got \(action)")
		}
	}

	@Test("multiple triggers matches first")
	func multipleTriggersMatchesFirst() {
		let trigger1 = makeTrigger(flags: .maskControl, scope: .underCursor)
		let trigger2 = makeTrigger(flags: .maskControl, scope: .currentScreen)
		let classifier = EventClassifier(triggers: [trigger1, trigger2], desktopTriggers: [])
		var session = RouterSessionState()
		let event = RouterEvent(type: .flagsChanged, flags: .maskControl, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		if case .window(.activateTrigger(let matched, cursor: _, preview: _)) = action {
			#expect(matched.configuration.scope == .underCursor)
		} else {
			Issue.record("expected activateTrigger, got \(action)")
		}
	}

	@Test("active trigger held with extra modifiers triggers release")
	func activeTriggerHeldWithExtraModifiersTriggersRelease() {
		let trigger = makeTrigger(flags: .maskControl)
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger)
		let event = RouterEvent(type: .flagsChanged, flags: [.maskControl, .maskShift], keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(action == .window(.triggerReleased))
		#expect(session.activeTrigger == nil)
	}

	@Test("switching to different trigger re-activates")
	func switchingToDifferentTriggerReactivates() {
		let trigger1 = makeTrigger(flags: .maskControl, scope: .underCursor)
		let trigger2 = makeTrigger(flags: .maskAlternate, scope: .currentScreen)
		let classifier = EventClassifier(triggers: [trigger1, trigger2], desktopTriggers: [])
		var session = RouterSessionState(activeTrigger: trigger1)
		let event = RouterEvent(type: .flagsChanged, flags: .maskAlternate, keyCode: 0, cursorLocation: CGPoint(x: 100, y: 200))
		let (_, action) = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		if case .window(.activateTrigger(let matched, cursor: _, preview: _)) = action {
			#expect(matched == trigger2)
		} else {
			Issue.record("expected activateTrigger, got \(action)")
		}
		#expect(session.activeTrigger == trigger2)
	}

	@Test("tap disabled clears all state")
	func tapDisabledClearsAllState() {
		let trigger = makeTrigger()
		let desktopTrigger = makeDesktopTrigger()
		let classifier = EventClassifier(triggers: [trigger], desktopTriggers: [desktopTrigger])
		var session = RouterSessionState(
			activeTrigger: trigger,
			activeDesktopTrigger: desktopTrigger,
			dockSessionActive: true
		)
		let event = RouterEvent(type: .tapDisabledByTimeout, flags: [], keyCode: 0, hasPermissions: false)
		_ = classifier.classify(event: event, dockHover: DockHoverInput(), session: &session)
		#expect(session.activeTrigger == nil)
		#expect(session.activeDesktopTrigger == nil)
	}
}
