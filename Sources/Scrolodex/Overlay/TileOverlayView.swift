import AppKit
import CoreGraphics
import ScrolodexCore

@MainActor
final class TileOverlayView: NSView, OverlayDrawing {
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
		static let tileGap: CGFloat = 8
		static let tileCornerRadius: CGFloat = 16
		static let thumbnailCornerRadius: CGFloat = 10
		static let appIconSize: CGFloat = 20
		static let appIconCornerRadius: CGFloat = 5
		static let primaryFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
		static let secondaryFont = NSFont.systemFont(ofSize: 11, weight: .regular)
		static let noPreviewFont = NSFont.systemFont(ofSize: 10, weight: .medium)
		static let verticalPadding: CGFloat = 10
	}

	private var transitionOffset: CGFloat { overlayAnimation.currentTransitionOffset }
	private var animatedBackgroundWidth: CGFloat? { overlayAnimation.currentAnimatedSize }
	private lazy var overlayAnimation: OverlayAnimation = {
		let anim = OverlayAnimation()
		anim.onUpdate = { [weak self] in self?.needsDisplay = true }
		return anim
	}()

	private var realCount: Int {
		rows.filter { !$0.primaryText.isEmpty }.count
	}

	private var tileWidth: CGFloat {
		let thumbnailHeight = tileHeight * 0.82
		return thumbnailHeight * 16 / 9
	}

	private var tileHeight: CGFloat {
		bounds.height - 2 * Layout.verticalPadding
	}

	private var tileStride: CGFloat {
		tileWidth + Layout.tileGap
	}

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

		updateTargetBackgroundWidth()

		guard animationEnabled else {
			overlayAnimation.resetTransition()
			needsDisplay = true
			return
		}

		if wasAnimationEnabled, previousSelectedIndex != selectedIndex, transitionDirection != 0 {
			overlayAnimation.startTransition(
				offset: CGFloat(
					OverlayTransition.initialOffset(for: transitionDirection, axis: .horizontal)))
		} else {
			overlayAnimation.resetTransition()
		}
		needsDisplay = true
	}

	override func draw(_ dirtyRect: NSRect) {
		guard !rows.isEmpty else { return }

		let centerIndex = clampedSelectedIndex
		let visibleTiles = self.visibleTiles(centerIndex: centerIndex)
		guard !visibleTiles.isEmpty else { return }

		let bgRect = animatedTileBackgroundRect(centerIndex: centerIndex)
		drawBackground(bgRect)

		NSGraphicsContext.saveGraphicsState()
		NSBezierPath(roundedRect: bgRect, xRadius: Layout.cornerRadius, yRadius: Layout.cornerRadius).addClip()

		drawTileBackgrounds(visibleTiles: visibleTiles, centerIndex: centerIndex)
		drawFixedSelectionHighlight(centerIndex: centerIndex)
		drawTileContents(visibleTiles: visibleTiles, centerIndex: centerIndex)

		NSGraphicsContext.restoreGraphicsState()
	}

	private var tilesTopY: CGFloat {
		bounds.height - Layout.verticalPadding
	}

	private func tileRect(for index: Int, centerIndex: Int, progress: CGFloat) -> CGRect {
		let centerX = bounds.width / 2 - tileWidth / 2
		let x = centerX + (CGFloat(index - centerIndex) + progress) * tileStride
		return CGRect(x: x, y: tilesTopY - tileHeight, width: tileWidth, height: tileHeight)
	}

	private func visibleTiles(centerIndex: Int) -> [(index: Int, localIndex: Int)] {
		let visibleBand = CGRect(
			x: -tileStride, y: 0, width: bounds.width + 2 * tileStride, height: bounds.height)

		return rows.enumerated().compactMap { localIndex, row in
			guard !row.primaryText.isEmpty else { return nil }
			let index = rowIndexOffset + localIndex
			let rect = tileRect(for: index, centerIndex: centerIndex, progress: transitionOffset)
			return rect.intersects(visibleBand) ? (index, localIndex) : nil
		}
	}

	private func realTileOffsets(for centerIndex: Int) -> [Int] {
		[-1, 0, 1].filter { offset in
			let index = centerIndex + offset
			let local = index - rowIndexOffset
			guard local >= 0, local < rows.count else { return false }
			return !rows[local].primaryText.isEmpty
		}
	}

	private func stableTileBackgroundRect(centerIndex: Int) -> CGRect {
		let padding: CGFloat = 16
		let highlightExtra: CGFloat = 6
		let strokeMargin: CGFloat = 1
		let offsets = realTileOffsets(for: centerIndex)
		let rects = offsets.map { offset -> CGRect in
			let tile = tileRect(for: centerIndex + offset, centerIndex: centerIndex, progress: 0)
			return offset == 0 ? tile.insetBy(dx: -highlightExtra, dy: -highlightExtra) : tile
		}
		let union = rects.reduce(CGRect.null) { $0.union($1) }
		let expanded = union.insetBy(dx: -padding, dy: -padding)
		return expanded.intersection(bounds.insetBy(dx: strokeMargin, dy: strokeMargin))
	}

	private func animatedTileBackgroundRect(centerIndex: Int) -> CGRect {
		let target = stableTileBackgroundRect(centerIndex: centerIndex)
		guard let width = animatedBackgroundWidth else { return target }
		let centerX = target.midX
		return CGRect(x: centerX - width / 2, y: target.minY, width: width, height: target.height)
	}

	private func updateTargetBackgroundWidth() {
		let centerIndex = clampedSelectedIndex
		let rect = stableTileBackgroundRect(centerIndex: centerIndex)
		overlayAnimation.setTargetSize(rect.width)
	}

	private func drawTileBackgrounds(visibleTiles: [(index: Int, localIndex: Int)], centerIndex: Int) {
		for tile in visibleTiles {
			let rect = tileRect(for: tile.index, centerIndex: centerIndex, progress: transitionOffset)
			NSColor.fromToken(colorTokens.unselectedFill).setFill()
			NSBezierPath(
				roundedRect: rect, xRadius: Layout.tileCornerRadius, yRadius: Layout.tileCornerRadius
			).fill()
		}
	}

	private func drawFixedSelectionHighlight(centerIndex: Int) {
		let tile = tileRect(for: centerIndex, centerIndex: centerIndex, progress: 0)
		let highlightInset: CGFloat = -6
		let rect = tile.insetBy(dx: highlightInset, dy: highlightInset)
		let path = NSBezierPath(
			roundedRect: rect, xRadius: Layout.tileCornerRadius + 4, yRadius: Layout.tileCornerRadius + 4)
		NSColor.fromToken(colorTokens.selectedFill).setFill()
		path.fill()
		NSColor.fromToken(colorTokens.selectedStroke).setStroke()
		path.lineWidth = 2
		path.stroke()
	}

	private func drawTileContents(visibleTiles: [(index: Int, localIndex: Int)], centerIndex: Int) {
		for tile in visibleTiles {
			let row = rows[tile.localIndex]
			let rect = tileRect(for: tile.index, centerIndex: centerIndex, progress: transitionOffset)
			drawTileContent(row: row, in: rect)
		}
	}

	private func drawTileContent(row: OverlayRowViewModel, in tileRect: CGRect) {
		let thumbnailHeight = tileRect.height * 0.82
		let thumbnailWidth = thumbnailHeight * 16 / 9
		let thumbnailX = tileRect.midX - thumbnailWidth / 2
		let thumbnailRect = CGRect(
			x: thumbnailX,
			y: tileRect.maxY - thumbnailHeight - 8,
			width: thumbnailWidth,
			height: thumbnailHeight
		)
		drawThumbnail(row.thumbnail, in: thumbnailRect)

		let textAreaTop = thumbnailRect.minY - 6
		let textX: CGFloat
		if let icon = row.appIcon {
			let titleCenterY = textAreaTop - 9
			let iconRect = CGRect(
				x: tileRect.minX + 10,
				y: titleCenterY - Layout.appIconSize / 2,
				width: Layout.appIconSize,
				height: Layout.appIconSize
			)
			drawAppIcon(icon, in: iconRect)
			textX = iconRect.maxX + 6
		} else {
			textX = tileRect.minX + 10
		}

		let availableTextWidth = tileRect.maxX - 10 - textX
		let primaryAttributes: [NSAttributedString.Key: Any] = [
			.font: Layout.primaryFont,
			.foregroundColor: NSColor.fromToken(colorTokens.primaryText),
		]
		let secondaryAttributes: [NSAttributedString.Key: Any] = [
			.font: Layout.secondaryFont,
			.foregroundColor: NSColor.fromToken(colorTokens.subtitleText),
		]
		NSString(string: row.primaryText).draw(
			in: CGRect(x: textX, y: textAreaTop - 18, width: availableTextWidth, height: 18),
			withAttributes: primaryAttributes
		)
		NSString(string: row.secondaryText).draw(
			in: CGRect(x: tileRect.minX + 10, y: textAreaTop - 32, width: tileRect.width - 20, height: 14),
			withAttributes: secondaryAttributes
		)
	}

	private func drawThumbnail(_ image: NSImage?, in rect: CGRect) {
		drawThumbnail(image, in: rect, noPreviewInsetX: 12, noPreviewInsetY: 20)
	}
}
