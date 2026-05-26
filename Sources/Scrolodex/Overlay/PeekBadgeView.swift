import AppKit
import ScrolodexCore

@MainActor
final class PeekBadgeView: NSView {
	var title = ""
	var subtitle = ""
	var appIcon: NSImage?
	var selectedIndex: Int = 1
	var totalCount: Int = 1
	var colorTokens: OverlayColorTokens = .tokens(for: .default)

	private var visualEffectView: NSVisualEffectView?

	override func viewDidMoveToSuperview() {
		super.viewDidMoveToSuperview()
		setupVisualEffect()
	}

	private func setupVisualEffect() {
		guard visualEffectView == nil else { return }
		let sv = superview ?? self

		let blur = NSVisualEffectView()
		blur.wantsLayer = true
		blur.blendingMode = .behindWindow
		blur.state = .active
		bleedBackground(into: blur)

		if self != sv {
			sv.addSubview(blur, positioned: .below, relativeTo: self)
		} else {
			addSubview(blur, positioned: .below, relativeTo: nil)
		}
		visualEffectView = blur
	}

	private func bleedBackground(into blur: NSVisualEffectView) {
		let t = colorTokens.badgeBackground
		let bg = NSColor(calibratedRed: t.red, green: t.green, blue: t.blue, alpha: t.alpha)
		blur.material = .hudWindow
		blur.wantsLayer = true
		blur.layer?.backgroundColor = bg.withAlphaComponent(0.35).cgColor
	}

	@MainActor private enum Layout {
		static let titleFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
		static let counterFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
		static let cornerRadius: CGFloat = 12
		static let horizontalPadding: CGFloat = 16
		static let verticalPadding: CGFloat = 10
		static let iconSize: CGFloat = 20
		static let iconCornerRadius: CGFloat = 5
		static let iconTextGap: CGFloat = 8
		static let rowGap: CGFloat = 6
		static let dotGap: CGFloat = 4
		static let dotSize: CGFloat = 6
		static let activeDotWidth: CGFloat = 18
		static let darkThreshold: CGFloat = 1.5
		static let counterGap: CGFloat = 8
		static let titleLineHeight: CGFloat = 18
		static let pillRowHeight: CGFloat = 6
	}

	func preferredSize(maxWidth: CGFloat = 520) -> CGSize {
		let iconWidth: CGFloat = appIcon != nil ? Layout.iconSize + Layout.iconTextGap : 0
		let titleSize = NSString(string: title).size(withAttributes: titleAttributes)
		let counterSize = counterAttributedString.size()
		let dotsWidth =
			CGFloat(totalCount - 1) * Layout.dotSize
			+ Layout.activeDotWidth
			+ CGFloat(max(0, totalCount - 1)) * Layout.dotGap
		let pillRowWidth = dotsWidth + Layout.counterGap + counterSize.width
		let contentWidth = max(
			titleSize.width + iconWidth,
			pillRowWidth + (appIcon != nil ? Layout.iconSize + Layout.iconTextGap : 0)
		)
		let width = min(contentWidth + Layout.horizontalPadding * 2, maxWidth)
		let height =
			Layout.verticalPadding
			+ Layout.titleLineHeight
			+ Layout.rowGap
			+ Layout.pillRowHeight
			+ Layout.verticalPadding
		return CGSize(width: width, height: height)
	}

	override func layout() {
		super.layout()
		visualEffectView?.frame = bounds
		visualEffectView?.layer?.cornerRadius = Layout.cornerRadius
		visualEffectView?.layer?.masksToBounds = true
	}

	override func draw(_ dirtyRect: NSRect) {
		NSColor.clear.setFill()
		bounds.fill()

		drawBackground()
		drawContent()
	}

	private func drawBackground() {
		let badgeRect = bounds
		let badgePath = NSBezierPath(
			roundedRect: badgeRect, xRadius: Layout.cornerRadius, yRadius: Layout.cornerRadius)

		let t = colorTokens.badgeBackground
		let bgColor = NSColor(calibratedRed: t.red, green: t.green, blue: t.blue, alpha: t.alpha)
		bgColor.setFill()
		badgePath.fill()

		let bt = colorTokens.badgeBorder
		let borderColor = NSColor(calibratedRed: bt.red, green: bt.green, blue: bt.blue, alpha: bt.alpha)
		if bt.alpha > 0.01 {
			borderColor.setStroke()
			badgePath.lineWidth = 0.5
			badgePath.stroke()
		}
	}

	private func drawContent() {
		let badgeRect = bounds

		let titleRowY = badgeRect.maxY - Layout.verticalPadding - Layout.titleLineHeight
		let pillRowY = titleRowY - Layout.rowGap - Layout.pillRowHeight

		var contentX = badgeRect.minX + Layout.horizontalPadding

		if let icon = appIcon {
			let iconRect = CGRect(
				x: contentX,
				y: titleRowY + (Layout.titleLineHeight - Layout.iconSize) / 2,
				width: Layout.iconSize,
				height: Layout.iconSize
			)
			drawAppIcon(icon, in: iconRect)
			contentX = iconRect.maxX + Layout.iconTextGap
		}

		let titleWidth = badgeRect.maxX - Layout.horizontalPadding - contentX
		NSString(string: title).draw(
			in: CGRect(x: contentX, y: titleRowY, width: titleWidth, height: Layout.titleLineHeight),
			withAttributes: titleAttributes
		)

		let pillStartX = contentX
		drawPillRow(x: pillStartX, y: pillRowY, availableWidth: titleWidth)
	}

	private func drawPillRow(x startX: CGFloat, y: CGFloat, availableWidth: CGFloat) {
		var dotX = startX
		let dotY = y

		for i in 0..<totalCount {
			let isActive = i == selectedIndex - 1
			let w = isActive ? Layout.activeDotWidth : Layout.dotSize
			let h = Layout.dotSize
			let rect = CGRect(x: dotX, y: dotY, width: w, height: h)
			let path = NSBezierPath(roundedRect: rect, xRadius: h / 2, yRadius: h / 2)

			if isActive {
				let activeColor: NSColor
				if isBadgeDark {
					activeColor = NSColor(white: 1.0, alpha: 0.55)
				} else {
					activeColor = NSColor(white: 0.0, alpha: 0.38)
				}
				activeColor.setFill()
			} else {
				let inactiveColor: NSColor
				if isBadgeDark {
					inactiveColor = NSColor(white: 1.0, alpha: 0.16)
				} else {
					inactiveColor = NSColor(white: 0.0, alpha: 0.10)
				}
				inactiveColor.setFill()
			}
			path.fill()

			dotX += w + Layout.dotGap
		}

		counterAttributedString.draw(at: CGPoint(x: dotX, y: y - 2))
	}

	private func drawAppIcon(_ image: NSImage, in rect: CGRect) {
		let path = NSBezierPath(
			roundedRect: rect, xRadius: Layout.iconCornerRadius, yRadius: Layout.iconCornerRadius)
		NSGraphicsContext.saveGraphicsState()
		path.addClip()
		image.draw(
			in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true,
			hints: [.interpolation: NSImageInterpolation.high])
		NSGraphicsContext.restoreGraphicsState()
	}

	private var isBadgeDark: Bool {
		let t = colorTokens.badgeBackground
		return t.red + t.green + t.blue < Layout.darkThreshold
	}

	private var titleAttributes: [NSAttributedString.Key: Any] {
		let textColor: NSColor
		if isBadgeDark {
			textColor = NSColor(white: 1.0, alpha: 0.88)
		} else {
			textColor = NSColor(white: 0.0, alpha: 0.82)
		}
		return [
			.font: Layout.titleFont,
			.foregroundColor: textColor,
		]
	}

	private var counterAttributedString: NSAttributedString {
		let dimColor: NSColor
		let brightColor: NSColor
		if isBadgeDark {
			dimColor = NSColor(white: 1.0, alpha: 0.28)
			brightColor = NSColor(white: 1.0, alpha: 0.62)
		} else {
			dimColor = NSColor(white: 0.0, alpha: 0.22)
			brightColor = NSColor(white: 0.0, alpha: 0.55)
		}
		let counterText = "\(selectedIndex)/\(totalCount)"
		let numRange = NSRange(location: 0, length: "\(selectedIndex)".utf16.count)
		let attrs: [NSAttributedString.Key: Any] = [
			.font: Layout.counterFont,
			.foregroundColor: dimColor,
		]
		let mas = NSMutableAttributedString(string: counterText, attributes: attrs)
		mas.addAttribute(.foregroundColor, value: brightColor, range: numRange)
		return mas
	}
}
