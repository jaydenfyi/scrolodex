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
	public let animate: Bool
	public let wrapAround: Bool

	public init(
		fingerCount: TrackpadFingerCount, scope: TriggerScope, filter: TriggerFilter,
		overlayMode: OverlayPresentationMode, peekEnabled: Bool, peekOpacity: Double, theme: OverlayTheme,
		monitorScope: MonitorScope, invertDirection: Bool, animate: Bool, wrapAround: Bool
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
		self.animate = animate
		self.wrapAround = wrapAround
	}
}
