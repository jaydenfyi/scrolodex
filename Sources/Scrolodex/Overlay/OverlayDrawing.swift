import AppKit
import ScrolodexCore

@MainActor
protocol OverlayDrawing: NSView {
	var colorTokens: OverlayColorTokens { get set }
	var selectedIndex: Int { get set }
	var rowIndexOffset: Int { get set }
	var rows: [OverlayRowViewModel] { get set }
	var overlayCornerRadius: CGFloat { get }
	var overlayThumbnailCornerRadius: CGFloat { get }
	var overlayAppIconCornerRadius: CGFloat { get }
}

extension OverlayDrawing {
	var clampedSelectedIndex: Int {
		let lowerBound = rowIndexOffset
		let upperBound = rowIndexOffset + rows.count - 1
		return min(max(selectedIndex, lowerBound), upperBound)
	}

	func drawBackground(_ rect: CGRect) {
		NSColor.fromToken(colorTokens.background).setFill()
		NSBezierPath(roundedRect: rect, xRadius: overlayCornerRadius, yRadius: overlayCornerRadius).fill()

		let borderPath = NSBezierPath(
			roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: overlayCornerRadius - 2,
			yRadius: overlayCornerRadius - 2)
		borderPath.lineWidth = 3
		NSColor.fromToken(colorTokens.border).setStroke()
		borderPath.stroke()
	}

	func drawThumbnail(_ image: NSImage?, in rect: CGRect, noPreviewInsetX: CGFloat, noPreviewInsetY: CGFloat) {
		let path = NSBezierPath(
			roundedRect: rect, xRadius: overlayThumbnailCornerRadius, yRadius: overlayThumbnailCornerRadius)
		NSColor.fromToken(colorTokens.thumbnailBackground).setFill()
		path.fill()

		guard let image else {
			let attributes: [NSAttributedString.Key: Any] = [
				.font: NSFont.systemFont(ofSize: 10, weight: .medium),
				.foregroundColor: NSColor.fromToken(colorTokens.noPreviewText),
			]
			NSString(string: "No preview").draw(
				in: rect.insetBy(dx: noPreviewInsetX, dy: noPreviewInsetY), withAttributes: attributes)
			return
		}

		NSGraphicsContext.saveGraphicsState()
		path.addClip()
		let fitRect = aspectFitRect(for: image, in: rect)
		image.draw(
			in: fitRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true,
			hints: [.interpolation: NSImageInterpolation.high])
		NSGraphicsContext.restoreGraphicsState()

		NSColor.fromToken(colorTokens.thumbnailBorder).setStroke()
		path.lineWidth = 1
		path.stroke()
	}

	func aspectFitRect(for image: NSImage, in rect: CGRect) -> CGRect {
		let size = image.size
		guard size.width > 0, size.height > 0 else { return rect }
		let imageAspect = size.width / size.height
		let rectAspect = rect.width / rect.height
		if imageAspect > rectAspect {
			let width = rect.width
			let height = width / imageAspect
			return CGRect(x: rect.minX, y: rect.midY - height / 2, width: width, height: height)
		} else {
			let height = rect.height
			let width = height * imageAspect
			return CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: height)
		}
	}

	func drawAppIcon(_ image: NSImage, in rect: CGRect) {
		let path = NSBezierPath(
			roundedRect: rect, xRadius: overlayAppIconCornerRadius, yRadius: overlayAppIconCornerRadius)
		NSGraphicsContext.saveGraphicsState()
		path.addClip()
		image.draw(
			in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true,
			hints: [.interpolation: NSImageInterpolation.high])
		NSGraphicsContext.restoreGraphicsState()
	}
}
