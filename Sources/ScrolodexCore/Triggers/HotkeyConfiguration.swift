import CoreGraphics

public struct HotkeyConfiguration: Equatable, Sendable {
	public let flags: CGEventFlags

	public static let defaultScrollAtPoint = HotkeyConfiguration(flags: [.maskAlternate])
	public static let defaultScrollAllWindows = HotkeyConfiguration(flags: [
		.maskCommand, .maskAlternate,
	])
	public static let defaultDesktopSwitch = HotkeyConfiguration(flags: [.maskAlternate, .maskShift])

	public init(flags: CGEventFlags) {
		self.flags = flags
	}

	public init(rawValue: UInt64) {
		self.flags = CGEventFlags(rawValue: rawValue)
	}

	public var displayName: String {
		let parts = ModifierDisplayName.names(from: flags)
		if parts.isEmpty { return "None" }
		return parts.joined(separator: " + ")
	}

	public var compactDisplayName: String {
		let parts = ModifierDisplayName.symbols(from: flags)
		if parts.isEmpty { return "None" }
		return parts.joined(separator: "")
	}

	public func matches(_ eventFlags: CGEventFlags) -> Bool {
		let modifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
		return eventFlags.intersection(modifiers) == flags.intersection(modifiers)
	}

	public func isSubsetOf(_ eventFlags: CGEventFlags) -> Bool {
		matches(eventFlags)
	}
}

enum ModifierDisplayName {
	static func names(from flags: CGEventFlags) -> [String] {
		components(from: flags, style: .name)
	}

	static func symbols(from flags: CGEventFlags) -> [String] {
		components(from: flags, style: .symbol)
	}

	private enum Style {
		case name
		case symbol
	}

	private static func components(from flags: CGEventFlags, style: Style) -> [String] {
		let mapping: [(CGEventFlags, String, String)] = [
			(.maskCommand, "Command", "⌘"),
			(.maskAlternate, "Option", "⌥"),
			(.maskControl, "Control", "⌃"),
			(.maskShift, "Shift", "⇧"),
		]
		return mapping.compactMap { flag, name, symbol in
			guard flags.contains(flag) else { return nil }
			return style == .name ? name : symbol
		}
	}
}
