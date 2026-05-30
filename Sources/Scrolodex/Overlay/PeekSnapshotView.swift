import AppKit
import ScrolodexCore

@MainActor
final class PeekSnapshotView: NSView {
	var image: NSImage?
	var imageOpacity: CGFloat = 0.94
	var borderOnly = false
	var showsBorder = true
	var title = ""
	var subtitle = ""
	var colorTokens: OverlayColorTokens = .tokens(for: .default)

	@MainActor private enum Layout {
		static let cornerRadius: CGFloat = 10
		static let borderWidth: CGFloat = 3
	}

	override func draw(_ dirtyRect: NSRect) {
		NSColor.clear.setFill()
		bounds.fill()

		if borderOnly {
			drawBorder()
			return
		}

		guard let image else { return }

		NSGraphicsContext.saveGraphicsState()
		let clipPath = NSBezierPath(
			roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: Layout.cornerRadius,
			yRadius: Layout.cornerRadius)
		clipPath.addClip()
		image.draw(
			in: bounds, from: .zero, operation: .sourceOver, fraction: imageOpacity, respectFlipped: true,
			hints: [.interpolation: NSImageInterpolation.high])
		NSGraphicsContext.restoreGraphicsState()

		if showsBorder {
			drawBorder()
		}
	}

	private func drawBorder() {
		let borderPath = NSBezierPath(
			roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: Layout.cornerRadius,
			yRadius: Layout.cornerRadius)
		borderPath.lineWidth = Layout.borderWidth
		NSColor.fromToken(colorTokens.peekBorder).setStroke()
		borderPath.stroke()
	}
}
