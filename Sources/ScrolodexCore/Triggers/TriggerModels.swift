import CoreGraphics
import Foundation

public struct TriggerHotkey: Equatable, Sendable {
	public let configuration: TriggerConfiguration
	public let hotkey: HotkeyConfiguration
	public let overlayMode: OverlayPresentationMode
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let theme: OverlayTheme
	public let monitorScope: MonitorScope
	public let showOnPress: Bool
	public let invertDirection: Bool
	public let animate: Bool
	public let wrapAround: Bool
	public let keyboardNavigation: KeyboardNavigationBinding

	public init(
		configuration: TriggerConfiguration, hotkey: HotkeyConfiguration, overlayMode: OverlayPresentationMode,
		peekEnabled: Bool, peekOpacity: Double, theme: OverlayTheme, monitorScope: MonitorScope,
		showOnPress: Bool, invertDirection: Bool, animate: Bool, wrapAround: Bool,
		keyboardNavigation: KeyboardNavigationBinding
	) {
		self.configuration = configuration
		self.hotkey = hotkey
		self.overlayMode = overlayMode
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
		self.monitorScope = monitorScope
		self.showOnPress = showOnPress
		self.invertDirection = invertDirection
		self.animate = animate
		self.wrapAround = wrapAround
		self.keyboardNavigation = keyboardNavigation
	}

	public func matches(_ flags: CGEventFlags) -> Bool {
		hotkey.matches(flags)
	}

	public var allKeyboardBindings: [KeyboardHotkeyConfiguration] {
		keyboardNavigation.allBindings
	}
}

public struct DesktopSwitchTrigger: Equatable, Sendable {
	public let hotkey: HotkeyConfiguration
	public let invertDirection: Bool
	public let animateScroll: Bool
	public let wrapAround: Bool
	public let keyboardNavigation: KeyboardNavigationBinding

	public init(
		hotkey: HotkeyConfiguration, invertDirection: Bool, animateScroll: Bool, wrapAround: Bool,
		keyboardNavigation: KeyboardNavigationBinding
	) {
		self.hotkey = hotkey
		self.invertDirection = invertDirection
		self.animateScroll = animateScroll
		self.wrapAround = wrapAround
		self.keyboardNavigation = keyboardNavigation
	}

	public func matches(_ flags: CGEventFlags) -> Bool {
		hotkey.matches(flags)
	}

	public var allKeyboardBindings: [KeyboardHotkeyConfiguration] {
		keyboardNavigation.allBindings
	}
}

public enum TrackpadFingerCount: Int, CaseIterable, Sendable {
	case three = 3
	case four = 4

	public var displayName: String {
		switch self {
		case .three: "3-Finger Swipe"
		case .four: "4-Finger Swipe"
		}
	}
}

public enum GestureSwipeAxis: Equatable, Sendable {
	case vertical
	case horizontal
}

public struct GestureSwipeNavigationDelta: Equatable, Sendable {
	public let axis: GestureSwipeAxis
	public let direction: Int

	public init(axis: GestureSwipeAxis, direction: Int) {
		self.axis = axis
		self.direction = direction
	}
}

public enum GestureSwipeIntent: Equatable, Sendable {
	case undecided
	case vertical
	case horizontal
}

public struct GestureSwipeNavigationResult: Equatable, Sendable {
	public let intent: GestureSwipeIntent
	public let navigation: GestureSwipeNavigationDelta?

	public init(intent: GestureSwipeIntent, navigation: GestureSwipeNavigationDelta?) {
		self.intent = intent
		self.navigation = navigation
	}
}

public enum GestureSwipeDirection: String, Equatable, Sendable {
	case vertical
	case horizontal

	public func navigationDelta(
		dx: CGFloat,
		dy: CGFloat,
		threshold: CGFloat,
		dominanceRatio: CGFloat,
		currentIntent: GestureSwipeIntent
	) -> GestureSwipeNavigationResult {
		let allowedAxis: GestureSwipeAxis = self == .horizontal ? .horizontal : .vertical
		return Self.restrictedDelta(
			allowedAxis: allowedAxis,
			dx: dx,
			dy: dy,
			threshold: threshold,
			dominanceRatio: dominanceRatio,
			currentIntent: currentIntent)
	}

	private static func restrictedDelta(
		allowedAxis: GestureSwipeAxis,
		dx: CGFloat,
		dy: CGFloat,
		threshold: CGFloat,
		dominanceRatio: CGFloat,
		currentIntent: GestureSwipeIntent
	) -> GestureSwipeNavigationResult {
		switch currentIntent {
		case .vertical:
			let navigation = allowedAxis == .vertical ? verticalDelta(dy: dy, threshold: threshold) : nil
			return GestureSwipeNavigationResult(intent: .vertical, navigation: navigation)
		case .horizontal:
			let navigation = allowedAxis == .horizontal ? horizontalDelta(dx: dx, threshold: threshold) : nil
			return GestureSwipeNavigationResult(intent: .horizontal, navigation: navigation)
		case .undecided:
			let absX = abs(dx)
			let absY = abs(dy)
			if absX > threshold, absX >= absY * dominanceRatio {
				let navigation = allowedAxis == .horizontal ? horizontalDelta(dx: dx, threshold: threshold) : nil
				return GestureSwipeNavigationResult(intent: .horizontal, navigation: navigation)
			}
			if absY > threshold, absY >= absX / dominanceRatio {
				let navigation = allowedAxis == .vertical ? verticalDelta(dy: dy, threshold: threshold) : nil
				return GestureSwipeNavigationResult(intent: .vertical, navigation: navigation)
			}
			return GestureSwipeNavigationResult(intent: .undecided, navigation: nil)
		}
	}

	private static func verticalDelta(dy: CGFloat, threshold: CGFloat) -> GestureSwipeNavigationDelta? {
		guard abs(dy) > threshold else { return nil }
		return GestureSwipeNavigationDelta(axis: .vertical, direction: dy < 0 ? -1 : 1)
	}

	private static func horizontalDelta(dx: CGFloat, threshold: CGFloat) -> GestureSwipeNavigationDelta? {
		guard abs(dx) > threshold else { return nil }
		return GestureSwipeNavigationDelta(axis: .horizontal, direction: dx > 0 ? -1 : 1)
	}
}

public struct GestureTriggerConfig: Equatable, Sendable {
	public let fingerCount: TrackpadFingerCount
	public let scope: TriggerScope
	public let filter: TriggerFilter
	public let overlayMode: OverlayPresentationMode
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let theme: OverlayTheme
	public let monitorScope: MonitorScope
	public let invertDirection: Bool
	public let swipeDirection: GestureSwipeDirection
	public let animate: Bool
	public let wrapAround: Bool

	public init(
		fingerCount: TrackpadFingerCount, scope: TriggerScope, filter: TriggerFilter,
		overlayMode: OverlayPresentationMode, peekEnabled: Bool, peekOpacity: Double, theme: OverlayTheme,
		monitorScope: MonitorScope, invertDirection: Bool, swipeDirection: GestureSwipeDirection, animate: Bool,
		wrapAround: Bool
	) {
		self.fingerCount = fingerCount
		self.scope = scope
		self.filter = filter
		self.overlayMode = overlayMode
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
		self.monitorScope = monitorScope
		self.invertDirection = invertDirection
		self.swipeDirection = swipeDirection
		self.animate = animate
		self.wrapAround = wrapAround
	}
}
