import CoreGraphics
import Foundation

public struct EventClassifier: Sendable {
	public let triggers: [TriggerHotkey]
	public let desktopTriggers: [DesktopSwitchTrigger]

	public init(
		triggers: [TriggerHotkey],
		desktopTriggers: [DesktopSwitchTrigger]
	) {
		self.triggers = triggers
		self.desktopTriggers = desktopTriggers
	}

	public func classify(
		event: RouterEvent,
		dockHover: DockHoverInput,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction) {
		if let result = handleTapState(event: event, session: &session) { return result }
		if let result = handlePermissionGuard(event: event, session: &session) { return result }

		let matchedTrigger = triggers.first { $0.matches(event.flags) }
		let matchedDesktopTrigger = desktopTriggers.first { $0.matches(event.flags) }
		let activeTriggerStillHeld = session.activeTrigger?.hotkey.isSubsetOf(event.flags) ?? false
		let triggerHeld = matchedTrigger != nil || activeTriggerStillHeld

		if let result = handleDesktopKeySwitch(event: event, session: &session) { return result }
		if let result = handleEscapeCancel(event: event, session: &session) { return result }

		if let result = handleDesktopTrigger(
			event: event,
			matchedDesktopTrigger: matchedDesktopTrigger,
			triggerHeld: matchedDesktopTrigger != nil,
			session: &session
		) { return result }

		if let result = handleDockHover(event: event, dockHover: dockHover, session: &session) { return result }

		return handlePolicyAction(
			event: event,
			matchedTrigger: matchedTrigger,
			triggerHeld: triggerHeld,
			activeTriggerStillHeld: activeTriggerStillHeld,
			session: &session
		)
	}

	private func handleTapState(
		event: RouterEvent,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		guard event.type == .tapDisabledByTimeout || event.type == .tapDisabledByUserInput else { return nil }

		if event.hasPermissions {
			return (.reenableTap, .none)
		} else {
			Log.info("event tap disabled while permissions unavailable; stopping instead of re-enabling")
			session.endAllSessions()
			return (.stopTap, .system(.permissionsLost))
		}
	}

	private func handlePermissionGuard(
		event: RouterEvent,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		guard !event.hasPermissions else { return nil }

		let hadActive = session.activeTrigger != nil || session.activeDesktopTrigger != nil
		if hadActive {
			Log.info("permissions lost while trigger active; resetting and passing events through")
		}
		session.endAllSessions()
		if hadActive {
			return (.stopTap, .system(.permissionsLost))
		}
		return (.passThrough, .none)
	}

	private func handleEscapeCancel(
		event: RouterEvent,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		let escapeKeyCode: CGKeyCode = 53
		guard event.type == .keyDown, event.keyCode == escapeKeyCode,
			  session.activeTrigger != nil || session.dockSessionActive else { return nil }
		if escapeMatchesActiveKeyboardBinding(event, session: session) { return nil }

		Log.debug("escape pressed during active session; canceling")
		session.endWindowAndDockSessions()
		return (.consume, .window(.escapeCancel))
	}

	private func handleDesktopKeySwitch(
		event: RouterEvent,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		guard event.type == .keyDown,
			  let (trigger, direction) = desktopSwitchDirection(flags: event.flags, keyCode: event.keyCode)
		else { return nil }

		session.beginDesktopSession(trigger: trigger)
		Log.debug("desktop keyboard switch direction=%d flags=%llu keyCode=%d", direction.rawValue, event.flags.rawValue, event.keyCode)
		return (.consume, .desktop(.switch(direction, trigger: trigger, cursor: event.cursorLocation)))
	}

	private func handleDesktopTrigger(
		event: RouterEvent,
		matchedDesktopTrigger: DesktopSwitchTrigger?,
		triggerHeld: Bool,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		if triggerHeld {
			switch event.type {
			case .flagsChanged:
				if let matched = matchedDesktopTrigger {
					session.beginDesktopSession(trigger: matched)
					Log.debug("desktop trigger detected flags=%llu", event.flags.rawValue)
				}
				return (.consumeAndPassthrough, .desktop(.activate(session.activeDesktopTrigger ?? desktopTriggers[0])))
			case .scrollWheel:
				Log.debug("desktop trigger scroll delta=%f", event.scrollDelta)
				if let matched = matchedDesktopTrigger {
					session.beginDesktopSession(trigger: matched)
				}
				if let switchDirection = session.accumulateDesktopScroll(delta: event.scrollDelta),
				   let trigger = session.activeDesktopTrigger
				{
					return (.consume, .desktop(.switch(switchDirection, trigger: trigger, cursor: event.cursorLocation)))
				}
				return (.consume, .none)
			case .leftMouseDown:
				return (.consumeAndPassthrough, .none)
			default:
				break
			}
		}

		if !triggerHeld && session.activeDesktopTrigger != nil && event.type == .flagsChanged {
			Log.debug("desktop trigger released flags=%llu", event.flags.rawValue)
			session.endDesktopSession()
			return (.consumeAndPassthrough, .desktop(.released))
		}

		if session.activeDesktopTrigger != nil && event.type == .scrollWheel {
			Log.debug("desktop trigger scroll (held) delta=%f", event.scrollDelta)
			if let switchDirection = session.accumulateDesktopScroll(delta: event.scrollDelta),
			   let trigger = session.activeDesktopTrigger
			{
				return (.consume, .desktop(.switch(switchDirection, trigger: trigger, cursor: event.cursorLocation)))
			}
			return (.consume, .none)
		}

		return nil
	}

	private func handleDockHover(
		event: RouterEvent,
		dockHover: DockHoverInput,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction)? {
		let dockConfig: DockHoverConfiguration?
		if event.type == .keyDown {
			dockConfig = dockHover.configs.first { config in
				config.enabled && dockKeyboardNavigationDirection(config: config, event: event) != nil
			}
		} else {
			dockConfig = dockHover.configs.first(where: { $0.enabled && $0.modifierMatches(event.flags) })
		}
		guard let dockConfig else { return nil }

		let modifierHeld = dockConfig.modifierMatches(event.flags)

		if event.type == .scrollWheel, modifierHeld,
		   let hoveredID = dockHover.hoveredBundleID,
		   hoveredID != dockHover.ownBundleID,
		   let frame = dockHover.hoveredItemFrame,
		   frame.contains(event.cursorLocation),
		   let anchor = dockHover.anchorPoint
		{
			Log.debug("dock hover scroll delta=%f bundle=%@", event.scrollDelta, hoveredID)
			session.beginDockSession()
			return (.consume, .dock(.scroll(delta: event.scrollDelta, config: dockConfig, anchor: anchor, bundleID: hoveredID)))
		}

		if event.type == .keyDown,
		   let hoveredID = dockHover.hoveredBundleID,
		   hoveredID != dockHover.ownBundleID,
		   let frame = dockHover.hoveredItemFrame,
		   frame.contains(event.cursorLocation),
		   let anchor = dockHover.anchorPoint,
		   let direction = dockKeyboardNavigationDirection(config: dockConfig, event: event)
		{
			Log.debug("dock hover keyboard navigate direction=%d bundle=%@", direction, hoveredID)
			session.beginDockSession()
			return (.consume, .dock(.keyboardNavigate(direction: direction, config: dockConfig, anchor: anchor, bundleID: hoveredID)))
		}

		if event.type == .flagsChanged, modifierHeld,
		   let hoveredID = dockHover.hoveredBundleID,
		   hoveredID != dockHover.ownBundleID,
		   let frame = dockHover.hoveredItemFrame,
		   frame.contains(event.cursorLocation),
		   let anchor = dockHover.anchorPoint
		{
			session.beginDockSession()
			if dockConfig.showOnPress {
				Log.debug("dock hover preview bundle=%@", hoveredID)
				return (.consumeAndPassthrough, .dock(.preview(config: dockConfig, anchor: anchor, bundleID: hoveredID)))
			}
			return (.consumeAndPassthrough, .none)
		}

		if event.type == .flagsChanged, !modifierHeld, session.dockSessionActive {
			Log.debug("dock hover trigger released")
			session.endDockSession()
			return (.consumeAndPassthrough, .dock(.released))
		}

		return nil
	}

	private func dockKeyboardNavigationDirection(config: DockHoverConfiguration, event: RouterEvent) -> Int? {
		guard config.keyboardNavigation.enabled else { return nil }
		if let forward = config.keyboardNavigation.forward, forward.matches(event.flags, event.keyCode) { return 1 }
		if let backward = config.keyboardNavigation.backward, backward.matches(event.flags, event.keyCode) { return -1 }
		return nil
	}

	private func handlePolicyAction(
		event: RouterEvent,
		matchedTrigger: TriggerHotkey?,
		triggerHeld: Bool,
		activeTriggerStillHeld: Bool,
		session: inout RouterSessionState
	) -> (RouterDirective, RouterAction) {
		let keyboardBindings: [KeyboardHotkeyConfiguration]
		if let active = session.activeTrigger {
			keyboardBindings = active.allKeyboardBindings
		} else {
			keyboardBindings = triggers.flatMap { $0.allKeyboardBindings }
		}

		let action = EventTapPolicy.action(
			for: event.type,
			eventFlags: event.flags,
			eventKeyCode: event.keyCode,
			triggerHeld: triggerHeld,
			keyboardBindings: keyboardBindings,
			permissionsAvailable: event.hasPermissions
		)

		switch action {
		case .previewTrigger:
			let shouldActivate = matchedTrigger != session.activeTrigger || session.activeTrigger == nil || !activeTriggerStillHeld
			if shouldActivate, let trigger = matchedTrigger {
				session.beginWindowSession(trigger: trigger)
				Log.debug("trigger detected flags=%llu cursor=%@", event.flags.rawValue, NSStringFromPoint(event.cursorLocation))
				return (.consumeAndPassthrough, .window(.activateTrigger(trigger, cursor: event.cursorLocation, preview: trigger.showOnPress)))
			}
			return (.consumeAndPassthrough, .none)
		case .handleScroll:
			let delta = event.scrollDelta
			Log.debug("trigger scroll flags=%llu delta=%f cursor=%@", event.flags.rawValue, delta, NSStringFromPoint(event.cursorLocation))
			return (.consume, .window(.scroll(delta, event.cursorLocation)))
		case .handleClickConfirm:
			Log.debug("trigger click confirm")
			return (.consumeAndPassthrough, .window(.clickConfirm))
		case .handleTriggerRelease:
			Log.debug("trigger released flags=%llu", event.flags.rawValue)
			session.endWindowSession()
			return (.consumeAndPassthrough, .window(.triggerReleased))
		case .handleKeyNavigate(let direction):
			let cursor = event.cursorLocation
			Log.debug("keyboard navigate direction=%d flags=%llu keyCode=%d cursor=%@", direction, event.flags.rawValue, event.keyCode, NSStringFromPoint(cursor))
			if session.activeTrigger == nil, let trigger = triggerForKeyBinding(flags: event.flags, keyCode: event.keyCode) {
				session.beginWindowSession(trigger: trigger)
			}
			return (.consume, .window(.keyboardNavigate(direction: direction, trigger: session.activeTrigger, cursor: cursor)))
		case .passThrough, .reenableTap:
			return (.passThrough, .none)
		}
	}

	private func escapeMatchesActiveKeyboardBinding(_ event: RouterEvent, session: RouterSessionState) -> Bool {
		if let activeTrigger = session.activeTrigger {
			return activeTrigger.allKeyboardBindings.contains { $0.matches(event.flags, event.keyCode) }
		}
		return triggers.flatMap { $0.allKeyboardBindings }.contains { $0.matches(event.flags, event.keyCode) }
	}

	private func triggerForKeyBinding(flags: CGEventFlags, keyCode: CGKeyCode) -> TriggerHotkey? {
		triggers.first { trigger in
			guard trigger.keyboardNavigation.enabled else { return false }
			if let forward = trigger.keyboardNavigation.forward, forward.matches(flags, keyCode) { return true }
			if let backward = trigger.keyboardNavigation.backward, backward.matches(flags, keyCode) { return true }
			return false
		}
	}

	private func desktopSwitchDirection(flags: CGEventFlags, keyCode: CGKeyCode) -> (DesktopSwitchTrigger, SpaceSwitchDirection)? {
		for trigger in desktopTriggers where trigger.keyboardNavigation.enabled {
			if let forward = trigger.keyboardNavigation.forward, forward.matches(flags, keyCode) {
				return (trigger, .right)
			}
			if let backward = trigger.keyboardNavigation.backward, backward.matches(flags, keyCode) {
				return (trigger, .left)
			}
		}
		return nil
	}
}
