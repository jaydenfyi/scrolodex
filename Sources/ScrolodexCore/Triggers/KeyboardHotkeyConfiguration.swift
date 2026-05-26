import Carbon.HIToolbox
import CoreGraphics
import Foundation

public struct KeyboardHotkeyConfiguration: Equatable, Sendable {
	public let flags: CGEventFlags
	public let keyCode: CGKeyCode

	public init(flags: CGEventFlags, keyCode: CGKeyCode) {
		self.flags = flags
		self.keyCode = keyCode
	}

	public func matches(_ eventFlags: CGEventFlags, _ eventKeyCode: CGKeyCode) -> Bool {
		let modifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskShift, .maskCommand]
		return eventFlags.intersection(modifiers) == flags.intersection(modifiers) && eventKeyCode == keyCode
	}

	public var displayName: String {
		let modifierParts = Self.modifierDisplayNameComponents(from: flags)
		let keyPart = Self.keyDisplayName(for: keyCode)
		let all = modifierParts + (keyPart.map { [$0] } ?? [])
		return all.isEmpty ? "None" : all.joined(separator: " + ")
	}

	public var compactDisplayName: String {
		let modifierParts = ModifierDisplayName.symbols(from: flags)
		let keyPart = Self.keyDisplayName(for: keyCode)
		let all = modifierParts + (keyPart.map { [$0] } ?? [])
		return all.isEmpty ? "None" : all.joined(separator: " + ")
	}

	public static func compactModifierDisplayName(from flags: CGEventFlags) -> String? {
		let parts = ModifierDisplayName.symbols(from: flags)
		return parts.isEmpty ? nil : parts.joined(separator: " + ")
	}

	private static let keyDisplayNames: [CGKeyCode: String] = [
		CGKeyCode(kVK_ANSI_A): "A",
		CGKeyCode(kVK_ANSI_S): "S",
		CGKeyCode(kVK_ANSI_D): "D",
		CGKeyCode(kVK_ANSI_F): "F",
		CGKeyCode(kVK_ANSI_H): "H",
		CGKeyCode(kVK_ANSI_G): "G",
		CGKeyCode(kVK_ANSI_Z): "Z",
		CGKeyCode(kVK_ANSI_X): "X",
		CGKeyCode(kVK_ANSI_C): "C",
		CGKeyCode(kVK_ANSI_V): "V",
		CGKeyCode(kVK_ANSI_B): "B",
		CGKeyCode(kVK_ANSI_Q): "Q",
		CGKeyCode(kVK_ANSI_W): "W",
		CGKeyCode(kVK_ANSI_E): "E",
		CGKeyCode(kVK_ANSI_R): "R",
		CGKeyCode(kVK_ANSI_Y): "Y",
		CGKeyCode(kVK_ANSI_T): "T",
		CGKeyCode(kVK_ANSI_1): "1",
		CGKeyCode(kVK_ANSI_2): "2",
		CGKeyCode(kVK_ANSI_3): "3",
		CGKeyCode(kVK_ANSI_4): "4",
		CGKeyCode(kVK_ANSI_6): "6",
		CGKeyCode(kVK_ANSI_5): "5",
		CGKeyCode(kVK_ANSI_Equal): "=",
		CGKeyCode(kVK_ANSI_9): "9",
		CGKeyCode(kVK_ANSI_7): "7",
		CGKeyCode(kVK_ANSI_Minus): "-",
		CGKeyCode(kVK_ANSI_8): "8",
		CGKeyCode(kVK_ANSI_0): "0",
		CGKeyCode(kVK_ANSI_RightBracket): "]",
		CGKeyCode(kVK_ANSI_O): "O",
		CGKeyCode(kVK_ANSI_U): "U",
		CGKeyCode(kVK_ANSI_LeftBracket): "[",
		CGKeyCode(kVK_ANSI_I): "I",
		CGKeyCode(kVK_ANSI_P): "P",
		CGKeyCode(kVK_ANSI_L): "L",
		CGKeyCode(kVK_ANSI_J): "J",
		CGKeyCode(kVK_ANSI_Quote): "'",
		CGKeyCode(kVK_ANSI_K): "K",
		CGKeyCode(kVK_ANSI_Semicolon): ";",
		CGKeyCode(kVK_ANSI_Backslash): "\\",
		CGKeyCode(kVK_ANSI_Comma): ",",
		CGKeyCode(kVK_ANSI_Slash): "/",
		CGKeyCode(kVK_ANSI_N): "N",
		CGKeyCode(kVK_ANSI_M): "M",
		CGKeyCode(kVK_ANSI_Period): ".",
		CGKeyCode(kVK_ANSI_Grave): "`",

		CGKeyCode(kVK_Return): "Return",
		CGKeyCode(kVK_Tab): "Tab",
		CGKeyCode(kVK_Space): "Space",
		CGKeyCode(kVK_Delete): "Delete",
		CGKeyCode(kVK_Escape): "Esc",
		CGKeyCode(kVK_ForwardDelete): "Forward Delete",
		CGKeyCode(kVK_Home): "Home",
		CGKeyCode(kVK_End): "End",
		CGKeyCode(kVK_PageUp): "Page Up",
		CGKeyCode(kVK_PageDown): "Page Down",
		CGKeyCode(kVK_LeftArrow): "Left",
		CGKeyCode(kVK_RightArrow): "Right",
		CGKeyCode(kVK_DownArrow): "Down",
		CGKeyCode(kVK_UpArrow): "Up",

		CGKeyCode(kVK_F1): "F1",
		CGKeyCode(kVK_F2): "F2",
		CGKeyCode(kVK_F3): "F3",
		CGKeyCode(kVK_F4): "F4",
		CGKeyCode(kVK_F5): "F5",
		CGKeyCode(kVK_F6): "F6",
		CGKeyCode(kVK_F7): "F7",
		CGKeyCode(kVK_F8): "F8",
		CGKeyCode(kVK_F9): "F9",
		CGKeyCode(kVK_F10): "F10",
		CGKeyCode(kVK_F11): "F11",
		CGKeyCode(kVK_F12): "F12",
		CGKeyCode(kVK_F13): "F13",
		CGKeyCode(kVK_F14): "F14",
		CGKeyCode(kVK_F15): "F15",
		CGKeyCode(kVK_F16): "F16",
		CGKeyCode(kVK_F17): "F17",
		CGKeyCode(kVK_F18): "F18",
		CGKeyCode(kVK_F19): "F19",
		CGKeyCode(kVK_F20): "F20",

		CGKeyCode(kVK_ANSI_Keypad0): "Keypad 0",
		CGKeyCode(kVK_ANSI_Keypad1): "Keypad 1",
		CGKeyCode(kVK_ANSI_Keypad2): "Keypad 2",
		CGKeyCode(kVK_ANSI_Keypad3): "Keypad 3",
		CGKeyCode(kVK_ANSI_Keypad4): "Keypad 4",
		CGKeyCode(kVK_ANSI_Keypad5): "Keypad 5",
		CGKeyCode(kVK_ANSI_Keypad6): "Keypad 6",
		CGKeyCode(kVK_ANSI_Keypad7): "Keypad 7",
		CGKeyCode(kVK_ANSI_Keypad8): "Keypad 8",
		CGKeyCode(kVK_ANSI_Keypad9): "Keypad 9",
		CGKeyCode(kVK_ANSI_KeypadClear): "Keypad Clear",
		CGKeyCode(kVK_ANSI_KeypadDecimal): "Keypad .",
		CGKeyCode(kVK_ANSI_KeypadDivide): "Keypad /",
		CGKeyCode(kVK_ANSI_KeypadEnter): "Keypad Enter",
		CGKeyCode(kVK_ANSI_KeypadEquals): "Keypad =",
		CGKeyCode(kVK_ANSI_KeypadMinus): "Keypad -",
		CGKeyCode(kVK_ANSI_KeypadMultiply): "Keypad *",
		CGKeyCode(kVK_ANSI_KeypadPlus): "Keypad +",
	]

	private static func modifierDisplayNameComponents(from flags: CGEventFlags) -> [String] {
		ModifierDisplayName.names(from: flags)
	}

	private static func keyDisplayName(for keyCode: CGKeyCode) -> String? {
		keyDisplayNames[keyCode]
	}
}
