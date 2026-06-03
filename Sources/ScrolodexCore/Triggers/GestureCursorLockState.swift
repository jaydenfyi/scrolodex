import CoreGraphics

public struct GestureCursorLockState: Sendable {
	public private(set) var anchor: CGPoint?

	public init(anchor: CGPoint? = nil) {
		self.anchor = anchor
	}

	@discardableResult
	public mutating func lock(at point: CGPoint) -> CGPoint {
		if let anchor { return anchor }
		anchor = point
		return point
	}

	public mutating func release() {
		anchor = nil
	}

	public mutating func refresh(to point: CGPoint) {
		guard anchor != nil else { return }
		anchor = point
	}
}
