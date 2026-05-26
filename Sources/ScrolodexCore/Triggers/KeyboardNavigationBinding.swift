import CoreGraphics

public struct KeyboardNavigationBinding: Equatable, Sendable {
	public var enabled: Bool
	public var forward: KeyboardHotkeyConfiguration?
	public var backward: KeyboardHotkeyConfiguration?

	public init(
		enabled: Bool = false, forward: KeyboardHotkeyConfiguration? = nil,
		backward: KeyboardHotkeyConfiguration? = nil
	) {
		self.enabled = enabled
		self.forward = forward
		self.backward = backward
	}

	public var allBindings: [KeyboardHotkeyConfiguration] {
		var result: [KeyboardHotkeyConfiguration] = []
		if enabled, let forward { result.append(forward) }
		if enabled, let backward { result.append(backward) }
		return result
	}
}
