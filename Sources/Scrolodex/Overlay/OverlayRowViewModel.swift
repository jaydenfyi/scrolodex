import AppKit
import CoreGraphics

struct OverlayRowViewModel {
	let windowID: CGWindowID
	let primaryText: String
	let secondaryText: String
	let isSelected: Bool
	let thumbnail: NSImage?
	let appIcon: NSImage?
}
