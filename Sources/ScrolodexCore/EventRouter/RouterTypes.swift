import CoreGraphics
import Foundation

public struct RouterEvent: Equatable, Sendable {
	public var type: CGEventType
	public var flags: CGEventFlags
	public var keyCode: CGKeyCode
	public var scrollDelta: Double
	public var cursorLocation: CGPoint
	public var hasPermissions: Bool

	public init(
		type: CGEventType,
		flags: CGEventFlags,
		keyCode: CGKeyCode,
		scrollDelta: Double = 0,
		cursorLocation: CGPoint = .zero,
		hasPermissions: Bool = true
	) {
		self.type = type
		self.flags = flags
		self.keyCode = keyCode
		self.scrollDelta = scrollDelta
		self.cursorLocation = cursorLocation
		self.hasPermissions = hasPermissions
	}
}

public struct DockHoverInput: Equatable, Sendable {
	public var configs: [DockHoverConfiguration]
	public var hoveredBundleID: String?
	public var hoveredItemFrame: CGRect?
	public var anchorPoint: CGPoint?
	public var ownBundleID: String

	public init(
		configs: [DockHoverConfiguration] = [],
		hoveredBundleID: String? = nil,
		hoveredItemFrame: CGRect? = nil,
		anchorPoint: CGPoint? = nil,
		ownBundleID: String = ""
	) {
		self.configs = configs
		self.hoveredBundleID = hoveredBundleID
		self.hoveredItemFrame = hoveredItemFrame
		self.anchorPoint = anchorPoint
		self.ownBundleID = ownBundleID
	}
}

public enum RouterDirective: Equatable, Sendable {
	case passThrough
	case consume
	case consumeAndPassthrough
	case stopTap
	case reenableTap
}

// ── Domain action types ──

public enum WindowAction: Equatable, Sendable {
	case activateTrigger(TriggerHotkey, cursor: CGPoint, preview: Bool)
	case scroll(Double, CGPoint)
	case clickConfirm
	case triggerReleased
	case keyboardNavigate(direction: Int, trigger: TriggerHotkey?, cursor: CGPoint)
	case escapeCancel
	case cursorMove(CGPoint)
}

public enum DesktopAction: Equatable, Sendable {
	case activate(DesktopSwitchTrigger)
	case `switch`(SpaceSwitchDirection, trigger: DesktopSwitchTrigger, cursor: CGPoint)
	case cursorMove(CGPoint)
	case released
}

public enum DockAction: Equatable, Sendable {
	case activate(config: DockHoverConfiguration, bundleID: String)
	case scroll(delta: Double, config: DockHoverConfiguration, anchor: CGPoint, bundleID: String)
	case preview(config: DockHoverConfiguration, anchor: CGPoint, bundleID: String)
	case keyboardNavigate(direction: Int, config: DockHoverConfiguration, anchor: CGPoint, bundleID: String)
	case released
}

public enum SystemAction: Equatable, Sendable {
	case permissionsLost
}

// ── Router action (thin wrapper) ──

public enum RouterAction: Equatable, Sendable {
	case none
	case window(WindowAction)
	case desktop(DesktopAction)
	case dock(DockAction)
	case system(SystemAction)
}
