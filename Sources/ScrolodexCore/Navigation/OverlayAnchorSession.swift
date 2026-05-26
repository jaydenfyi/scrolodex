import CoreGraphics

public struct OverlayAnchorSession: Sendable {
	private var initialAnchor: CGPoint?

	public init() {}

	public mutating func anchor(startingAt point: CGPoint) -> CGPoint {
		if let initialAnchor {
			return initialAnchor
		}

		initialAnchor = point
		return point
	}

	public mutating func reset() {
		initialAnchor = nil
	}
}
