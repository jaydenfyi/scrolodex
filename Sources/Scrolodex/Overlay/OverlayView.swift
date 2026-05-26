import AppKit
import CoreGraphics
import ScrolodexCore

@MainActor
final class OverlayView: NSView, OverlayDrawing {
	var scrollAnimationEnabled = false
	var selectedIndex = 0
	var rowIndexOffset = 0
	var rows: [OverlayRowViewModel] = []
	var colorTokens: OverlayColorTokens = .tokens(for: .default)

	var overlayCornerRadius: CGFloat { Layout.cornerRadius }
	var overlayThumbnailCornerRadius: CGFloat { Layout.thumbnailCornerRadius }
	var overlayAppIconCornerRadius: CGFloat { Layout.appIconCornerRadius }

	@MainActor private enum Layout {
		static let cornerRadius: CGFloat = 22
		static let rowHeight: CGFloat = 96
		static let rowCornerRadius: CGFloat = 16
		static let thumbnailWidth: CGFloat = 112
		static let thumbnailCornerRadius: CGFloat = 10
		static let appIconSize: CGFloat = 20
		static let appIconCornerRadius: CGFloat = 5
		static let primaryFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
		static let secondaryFont = NSFont.systemFont(ofSize: 11, weight: .regular)
		static let noPreviewFont = NSFont.systemFont(ofSize: 10, weight: .medium)
	}

	private var transitionOffset: CGFloat { overlayAnimation.currentTransitionOffset }
	private var animatedBackgroundHeight: CGFloat? { overlayAnimation.currentAnimatedSize }
	private lazy var overlayAnimation: OverlayAnimation = {
		let anim = OverlayAnimation()
		anim.onUpdate = { [weak self] in self?.needsDisplay = true }
		return anim
	}()

	func configure(
		rows: [OverlayRowViewModel],
		selectedIndex: Int,
		rowIndexOffset: Int,
		transitionDirection: Int,
		animationEnabled: Bool
	) {
		let previousSelectedIndex = self.selectedIndex
		let wasAnimationEnabled = scrollAnimationEnabled

		self.rows = rows
		self.rowIndexOffset = rowIndexOffset
		self.scrollAnimationEnabled = animationEnabled
		self.selectedIndex = selectedIndex

		updateTargetBackgroundHeight()

		guard animationEnabled else {
			overlayAnimation.resetTransition()
			needsDisplay = true
			return
		}

		if wasAnimationEnabled, previousSelectedIndex != selectedIndex, transitionDirection != 0 {
			overlayAnimation.startTransition(
				offset: CGFloat(
					OverlayTransition.initialOffset(for: transitionDirection, axis: .vertical)))
		} else {
			overlayAnimation.resetTransition()
		}
		needsDisplay = true
	}

	private func updateTargetBackgroundHeight() {
		let centerIndex = clampedSelectedIndex
		let rect = stableBackgroundRect(centerIndex: centerIndex)
		overlayAnimation.setTargetSize(rect.height)
	}

	override func draw(_ dirtyRect: NSRect) {
		guard !rows.isEmpty else { return }

		let centerIndex = clampedSelectedIndex
		let bgRect = animatedBackgroundRect(centerIndex: centerIndex)
		drawBackground(bgRect)

		NSGraphicsContext.saveGraphicsState()
		NSBezierPath(roundedRect: bgRect, xRadius: Layout.cornerRadius, yRadius: Layout.cornerRadius).addClip()

		drawRowBackgrounds(centerIndex: centerIndex)
		drawFixedSelectionHighlight(centerIndex: centerIndex)
		drawRowContents(centerIndex: centerIndex)

		NSGraphicsContext.restoreGraphicsState()
	}

	private var centerRowTop: CGFloat {
		bounds.height - 76 - 1 * Layout.rowHeight
	}

	private func visibleRowRects(centerIndex: Int) -> [(index: Int, rect: CGRect)] {
		let topVisible = rowRect(for: centerIndex - 2, centerIndex: centerIndex, progress: 0).maxY
		let bottomVisible = rowRect(for: centerIndex + 2, centerIndex: centerIndex, progress: 0).minY
		let visibleBand = CGRect(
			x: 0, y: bottomVisible, width: bounds.width, height: topVisible - bottomVisible)

		return rows.enumerated().compactMap { localIndex, row in
			guard !row.primaryText.isEmpty else { return nil }
			let index = rowIndexOffset + localIndex
			let rect = rowRect(for: index, centerIndex: centerIndex, progress: transitionOffset)
			return rect.intersects(visibleBand) ? (index, rect) : nil
		}
	}

	private func realRowOffsets(for centerIndex: Int) -> [Int] {
		[-1, 0, 1].filter { offset in
			let index = centerIndex + offset
			let local = index - rowIndexOffset
			guard local >= 0, local < rows.count else { return false }
			return !rows[local].primaryText.isEmpty
		}
	}

	private func stableBackgroundRect(centerIndex: Int) -> CGRect {
		let offsets = realRowOffsets(for: centerIndex)
		let rects = offsets.map { rowRect(for: centerIndex + $0, centerIndex: centerIndex, progress: 0) }
		let top = rects.map(\.maxY).max() ?? bounds.midY
		let bottom = rects.map(\.minY).min() ?? bounds.midY
		let topPadding: CGFloat = 16
		let bottomPadding: CGFloat = 8
		let strokeMargin: CGFloat = 1
		let rect = CGRect(
			x: strokeMargin, y: bottom - bottomPadding, width: bounds.width - 2 * strokeMargin,
			height: top - bottom + topPadding + bottomPadding)
		return rect.intersection(bounds.insetBy(dx: strokeMargin, dy: strokeMargin))
	}

	private func animatedBackgroundRect(centerIndex: Int) -> CGRect {
		let target = stableBackgroundRect(centerIndex: centerIndex)
		guard let height = animatedBackgroundHeight else { return target }
		let centerY = target.midY
		return CGRect(x: target.minX, y: centerY - height / 2, width: target.width, height: height)
	}

	private func drawRowBackgrounds(centerIndex: Int) {
		for (localIndex, row) in rows.enumerated() where !row.primaryText.isEmpty {
			let index = rowIndexOffset + localIndex
			let rect = rowRect(for: index, centerIndex: centerIndex, progress: transitionOffset)
			NSColor.fromToken(colorTokens.unselectedFill).setFill()
			NSBezierPath(
				roundedRect: rect, xRadius: Layout.rowCornerRadius, yRadius: Layout.rowCornerRadius
			).fill()
		}
	}

	private func drawFixedSelectionHighlight(centerIndex: Int) {
		let rect = rowRect(for: centerIndex, centerIndex: centerIndex, progress: 0)
		let path = NSBezierPath(
			roundedRect: rect, xRadius: Layout.rowCornerRadius, yRadius: Layout.rowCornerRadius)
		NSColor.fromToken(colorTokens.selectedFill).setFill()
		path.fill()
		NSColor.fromToken(colorTokens.selectedStroke).setStroke()
		path.lineWidth = 1
		path.stroke()
	}

	private func drawRowContents(centerIndex: Int) {
		for (localIndex, row) in rows.enumerated() where !row.primaryText.isEmpty {
			let index = rowIndexOffset + localIndex
			drawContent(
				row: row, in: rowRect(for: index, centerIndex: centerIndex, progress: transitionOffset))
		}
	}

	private func rowRect(for index: Int, centerIndex: Int, progress: CGFloat) -> CGRect {
		let rowY = rowTopY(for: index, centerIndex: centerIndex, progress: progress)
		return CGRect(
			x: 12, y: rowY - Layout.rowHeight + 8, width: bounds.width - 24, height: Layout.rowHeight - 8)
	}

	private func rowTopY(for index: Int, centerIndex: Int, progress: CGFloat) -> CGFloat {
		centerRowTop - CGFloat(index - centerIndex) * Layout.rowHeight + progress * Layout.rowHeight
	}

	private func drawContent(row: OverlayRowViewModel, in rowRect: CGRect) {
		let thumbnailRect = CGRect(
			x: rowRect.minX + 10, y: rowRect.minY + 10, width: Layout.thumbnailWidth,
			height: rowRect.height - 20)
		drawThumbnail(row.thumbnail, in: thumbnailRect)

		let textX: CGFloat
		if let icon = row.appIcon {
			let titleRectY = rowRect.midY + 3
			let titleCenterY = titleRectY + 11
			let iconRect = CGRect(
				x: thumbnailRect.maxX + 14, y: titleCenterY - Layout.appIconSize / 2,
				width: Layout.appIconSize, height: Layout.appIconSize)
			drawAppIcon(icon, in: iconRect)
			textX = iconRect.maxX + 8
		} else {
			textX = thumbnailRect.maxX + 14
		}

		let primaryAttributes: [NSAttributedString.Key: Any] = [
			.font: Layout.primaryFont,
			.foregroundColor: NSColor.fromToken(colorTokens.primaryText),
		]
		let secondaryAttributes: [NSAttributedString.Key: Any] = [
			.font: Layout.secondaryFont,
			.foregroundColor: NSColor.fromToken(colorTokens.subtitleText),
		]
		NSString(string: row.primaryText).draw(
			in: CGRect(x: textX, y: rowRect.midY + 3, width: rowRect.maxX - textX - 18, height: 22),
			withAttributes: primaryAttributes
		)
		NSString(string: row.secondaryText).draw(
			in: CGRect(x: textX, y: rowRect.midY - 18, width: rowRect.maxX - textX - 18, height: 18),
			withAttributes: secondaryAttributes
		)
	}

	private func drawThumbnail(_ image: NSImage?, in rect: CGRect) {
		drawThumbnail(image, in: rect, noPreviewInsetX: 18, noPreviewInsetY: 24)
	}
}
