import CoreGraphics
import Foundation

public enum OverlayPlacement {
	public struct ScreenMapping: Equatable, Sendable {
		public let cgBounds: CGRect
		public let appKitFrame: CGRect

		public init(cgBounds: CGRect, appKitFrame: CGRect) {
			self.cgBounds = cgBounds
			self.appKitFrame = appKitFrame
		}
	}

	private enum ListLayout {
		static let width: CGFloat = 680
		static let rowHeight: CGFloat = 104
		static let rowCount = 3
		static let chromeHeight: CGFloat = 88
		static var height: CGFloat { CGFloat(rowCount) * rowHeight + chromeHeight }
	}

	private enum TooltipLayout {
		static let width: CGFloat = 420
		static let height: CGFloat = 120
		static let cursorOffset: CGFloat = 16
		static let edgeMargin: CGFloat = 20
	}

	private enum TileLayout {
		static let height: CGFloat = 320
		static let sideMargin: CGFloat = 24
		static let fallbackWidth: CGFloat = 800
	}

	enum Fallback {
		static let defaultMargin: CGFloat = 24
		static let cursorOffset: CGFloat = 18
	}

	public static func frame(
		preferredSize: CGSize,
		anchorBounds: CGRect,
		screenBounds: CGRect,
		margin: CGFloat = 24
	) -> CGRect {
		let x = anchorBounds.midX - preferredSize.width / 2
		let y = anchorBounds.midY - preferredSize.height / 2

		return CGRect(
			x: clamp(
				x, min: screenBounds.minX + margin,
				max: screenBounds.maxX - preferredSize.width - margin),
			y: clamp(
				y, min: screenBounds.minY + margin,
				max: screenBounds.maxY - preferredSize.height - margin),
			width: preferredSize.width,
			height: preferredSize.height
		)
	}

	public static func appKitFrame(
		fromCGWindowBounds cgBounds: CGRect,
		screens: [ScreenMapping]
	) -> CGRect {
		let center = CGPoint(x: cgBounds.midX, y: cgBounds.midY)
		guard
			let screen = screens.first(where: { $0.cgBounds.contains(center) })
				?? nearestScreen(to: center, screens: screens)
		else {
			return cgBounds
		}

		let localX = cgBounds.minX - screen.cgBounds.minX
		let localY = cgBounds.minY - screen.cgBounds.minY

		return CGRect(
			x: screen.appKitFrame.minX + localX,
			y: screen.appKitFrame.maxY - localY - cgBounds.height,
			width: cgBounds.width,
			height: cgBounds.height
		)
	}

	public static func appKitPoint(
		fromCGDisplayPoint point: CGPoint,
		screens: [ScreenMapping]
	) -> CGPoint {
		guard
			let screen = screens.first(where: { $0.cgBounds.contains(point) })
				?? nearestScreen(to: point, screens: screens)
		else {
			return point
		}

		let localX = point.x - screen.cgBounds.minX
		let localY = point.y - screen.cgBounds.minY
		return CGPoint(
			x: screen.appKitFrame.minX + localX,
			y: screen.appKitFrame.maxY - localY
		)
	}

	public static func bestFrame(
		from frames: [CGRect],
		containingOrNearestTo point: CGPoint
	) -> CGRect? {
		if let containing = frames.first(where: { $0.contains(point) }) {
			return containing
		}

		return frames.min { lhs, rhs in
			squaredDistance(from: point, to: lhs) < squaredDistance(from: point, to: rhs)
		}
	}

	public static func screenBounds(
		forAnchorBounds anchorBounds: CGRect,
		mouseLocation: CGPoint,
		screens: [CGRect]
	) -> CGRect? {
		let anchorCenter = CGPoint(x: anchorBounds.midX, y: anchorBounds.midY)
		return screens.first(where: { $0.contains(anchorCenter) })
			?? screens.first(where: { !$0.intersection(anchorBounds).isNull })
			?? screens.first(where: { $0.contains(mouseLocation) })
			?? screens.min { lhs, rhs in
				squaredDistance(from: anchorCenter, to: lhs)
					< squaredDistance(from: anchorCenter, to: rhs)
			}
	}

	public static func resolveAppKitFrame(
		fromCGWindowBounds cgBounds: CGRect,
		screenMappings: [ScreenMapping],
		desktopUnionFrame: CGRect,
		primaryScreenHeight: CGFloat,
		mouseLocation: CGPoint
	) -> CGRect {
		var candidates: [CGRect] = []

		if !screenMappings.isEmpty {
			candidates.append(appKitFrame(fromCGWindowBounds: cgBounds, screens: screenMappings))
		}

		if !desktopUnionFrame.isNull {
			candidates.append(
				CGRect(
					x: cgBounds.minX,
					y: desktopUnionFrame.maxY - cgBounds.maxY,
					width: cgBounds.width,
					height: cgBounds.height
				))
		}

		if primaryScreenHeight > 0 {
			candidates.append(
				CGRect(
					x: cgBounds.minX,
					y: primaryScreenHeight - cgBounds.minY - cgBounds.height,
					width: cgBounds.width,
					height: cgBounds.height
				))
		}

		let deduplicated = Array(NSOrderedSet(array: candidates).compactMap { $0 as? CGRect })
		return bestFrame(from: deduplicated, containingOrNearestTo: mouseLocation) ?? cgBounds
	}

	public static func listOverlayFrame(
		candidateCount: Int,
		selectedBounds: CGRect?,
		cursor: CGPoint,
		screens: [CGRect]
	) -> CGRect {
		let width = ListLayout.width
		let height = ListLayout.height

		if let anchorBounds = selectedBounds {
			guard
				let screenBounds = screenBounds(
					forAnchorBounds: anchorBounds,
					mouseLocation: cursor,
					screens: screens
				)
			else {
				return CGRect(x: cursor.x + Fallback.cursorOffset, y: cursor.y + Fallback.cursorOffset, width: width, height: height)
			}
			return frame(
				preferredSize: CGSize(width: width, height: height),
				anchorBounds: anchorBounds,
				screenBounds: screenBounds
			)
		}

		let size = CGSize(width: TooltipLayout.width, height: TooltipLayout.height)
		guard let primary = screens.first else {
			return CGRect(origin: cursor, size: size)
		}
		return CGRect(
			x: min(
				max(cursor.x + TooltipLayout.cursorOffset, TooltipLayout.edgeMargin),
				primary.width - size.width - TooltipLayout.edgeMargin),
			y: min(
				max(
					primary.height - cursor.y - size.height - TooltipLayout.cursorOffset,
					TooltipLayout.edgeMargin),
				primary.height - size.height - TooltipLayout.edgeMargin
			),
			width: size.width,
			height: size.height
		)
	}

	public static func tileOverlayFrame(
		candidateCount: Int,
		selectedBounds: CGRect?,
		cursor: CGPoint,
		screens: [CGRect]
	) -> CGRect {
		let height = TileLayout.height
		let sideMargin = TileLayout.sideMargin

		guard
			let screenBounds = selectedBounds.map({
				screenBounds(forAnchorBounds: $0, mouseLocation: cursor, screens: screens)
			}) ?? screens.first
		else {
			return CGRect(x: cursor.x + Fallback.cursorOffset, y: cursor.y + Fallback.cursorOffset, width: TileLayout.fallbackWidth, height: height)
		}

		let width = screenBounds.width - 2 * sideMargin
		let x = screenBounds.minX + sideMargin
		let y: CGFloat
		if let anchorBounds = selectedBounds {
			y = clamp(
				anchorBounds.midY - height / 2,
				min: screenBounds.minY + sideMargin,
				max: screenBounds.maxY - height - sideMargin
			)
		} else {
			y = clamp(
				screenBounds.maxY - cursor.y - height - sideMargin,
				min: screenBounds.minY + sideMargin,
				max: screenBounds.maxY - height - sideMargin
			)
		}
		return CGRect(x: x, y: y, width: width, height: height)
	}

	private static func nearestScreen(to point: CGPoint, screens: [ScreenMapping]) -> ScreenMapping? {
		screens.min { lhs, rhs in
			squaredDistance(from: point, to: lhs.cgBounds) < squaredDistance(from: point, to: rhs.cgBounds)
		}
	}

	private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
		let clampedX = clamp(point.x, min: rect.minX, max: rect.maxX)
		let clampedY = clamp(point.y, min: rect.minY, max: rect.maxY)
		let dx = point.x - clampedX
		let dy = point.y - clampedY
		return dx * dx + dy * dy
	}

	private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
		guard min <= max else { return min }
		return Swift.min(Swift.max(value, min), max)
	}
}
