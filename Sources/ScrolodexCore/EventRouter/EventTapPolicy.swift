import CoreGraphics

public enum EventTapAction: Equatable, Sendable {
	case passThrough
	case handleScroll
	case handleClickConfirm
	case previewTrigger
	case handleTriggerRelease
	case handleKeyNavigate(direction: Int)
	case handleCursorMove
	case reenableTap
}

public enum EventTapPolicy {
	public static let observedEventTypes: [CGEventType] = [
		.scrollWheel,
		.leftMouseDown,
		.flagsChanged,
		.keyDown,
		.mouseMoved,
		.tapDisabledByTimeout,
		.tapDisabledByUserInput,
	]

	public static func action(for type: CGEventType, triggerHeld: Bool, permissionsAvailable: Bool)
		-> EventTapAction
	{
		action(
			for: type, eventFlags: [], eventKeyCode: 0, triggerHeld: triggerHeld, keyboardBindings: [],
			permissionsAvailable: permissionsAvailable)
	}

	public static func action(
		for type: CGEventType,
		eventFlags: CGEventFlags,
		eventKeyCode: CGKeyCode,
		triggerHeld: Bool,
		keyboardBindings: [KeyboardHotkeyConfiguration],
		permissionsAvailable: Bool
	) -> EventTapAction {
		switch type {
		case _ where !permissionsAvailable:
			return .passThrough
		case .tapDisabledByTimeout, .tapDisabledByUserInput:
			return .reenableTap
		case .keyDown:
			for (index, binding) in keyboardBindings.enumerated() {
				if binding.matches(eventFlags, eventKeyCode) {
					let direction = index % 2 == 0 ? 1 : -1
					return .handleKeyNavigate(direction: direction)
				}
			}
			return .passThrough
		case .flagsChanged where triggerHeld:
			return .previewTrigger
		case .scrollWheel where triggerHeld:
			return .handleScroll
		case .leftMouseDown where triggerHeld:
			return .handleClickConfirm
		case .mouseMoved where triggerHeld:
			return .handleCursorMove
		case .flagsChanged where !triggerHeld:
			return .handleTriggerRelease
		default:
			return .passThrough
		}
	}
}
