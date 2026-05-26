import AppKit
import CoreGraphics

@MainActor
final class ThumbnailProvider {
	private var cache: [CGWindowID: NSImage] = [:]

	func thumbnail(for windowID: CGWindowID) -> NSImage? {
		if let cached = cache[windowID] {
			return cached
		}

		guard
			let image = CGWindowListCreateImage(
				.null,
				.optionIncludingWindow,
				windowID,
				[.boundsIgnoreFraming, .bestResolution]
			)
		else {
			return nil
		}
		let thumbnail = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
		cache[windowID] = thumbnail
		return thumbnail
	}

	func clear() {
		cache.removeAll()
	}
}
