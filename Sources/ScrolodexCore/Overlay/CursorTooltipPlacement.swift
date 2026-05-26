import CoreGraphics

public enum CursorTooltipPlacement {
	public static func frame(
		size: CGSize,
		cursor: CGPoint,
		screens: [CGRect],
		offset: CGSize = CGSize(width: 14, height: 6),
		margin: CGFloat = 8
	) -> CGRect {
		let screen =
			screens.first(where: { $0.contains(cursor) }) ?? screens.first
			?? CGRect(origin: .zero, size: size)
		let proposed = CGPoint(x: cursor.x + offset.width, y: cursor.y + offset.height)
		let x = min(max(proposed.x, screen.minX + margin), screen.maxX - size.width - margin)
		let y = min(max(proposed.y, screen.minY + margin), screen.maxY - size.height - margin)
		return CGRect(origin: CGPoint(x: x, y: y), size: size)
	}
}
