import CoreGraphics
import Foundation

public struct RouterSessionState: Sendable {
	public private(set) var activeTrigger: TriggerHotkey?
	public private(set) var activeDesktopTrigger: DesktopSwitchTrigger?
	public private(set) var dockSessionActive: Bool = false
	public var desktopScrollAccumulator: DesktopScrollAccumulator

	public init(
		activeTrigger: TriggerHotkey? = nil,
		activeDesktopTrigger: DesktopSwitchTrigger? = nil,
		dockSessionActive: Bool = false,
		desktopScrollThreshold: Double = ScrollSensitivity.default
	) {
		self.activeTrigger = activeTrigger
		self.activeDesktopTrigger = activeDesktopTrigger
		self.dockSessionActive = dockSessionActive
		self.desktopScrollAccumulator = DesktopScrollAccumulator(threshold: desktopScrollThreshold)
	}

	public mutating func beginWindowSession(trigger: TriggerHotkey) {
		activeTrigger = trigger
	}

	public mutating func endWindowSession() {
		activeTrigger = nil
	}

	public mutating func beginDesktopSession(trigger: DesktopSwitchTrigger) {
		activeDesktopTrigger = trigger
	}

	public mutating func endDesktopSession() {
		activeDesktopTrigger = nil
		desktopScrollAccumulator.reset()
	}

	public mutating func beginDockSession() {
		dockSessionActive = true
	}

	public mutating func endDockSession() {
		dockSessionActive = false
	}

	public mutating func endWindowAndDockSessions() {
		activeTrigger = nil
		dockSessionActive = false
	}

	public mutating func endAllSessions() {
		activeTrigger = nil
		activeDesktopTrigger = nil
		dockSessionActive = false
	}

	@discardableResult
	public mutating func accumulateDesktopScroll(delta: Double) -> SpaceSwitchDirection? {
		desktopScrollAccumulator.apply(delta: delta)
	}
}
