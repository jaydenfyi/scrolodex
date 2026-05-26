import AppKit
import ScrolodexCore

extension NSColor {
	static func fromToken(_ token: TokenColor) -> NSColor {
		NSColor(calibratedRed: token.red, green: token.green, blue: token.blue, alpha: token.alpha)
	}
}
