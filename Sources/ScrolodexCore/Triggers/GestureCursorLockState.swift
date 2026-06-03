import CoreGraphics

public enum GestureCursorLockState: Sendable, Equatable {
	case idle
	case locked(anchor: CGPoint)
	case frozen(anchor: CGPoint)

	public init() {
		self = .idle
	}

	public var anchor: CGPoint? {
		switch self {
		case .idle: nil
		case .locked(let anchor), .frozen(let anchor): anchor
		}
	}

	public var isFrozen: Bool {
		if case .frozen = self { return true }
		return false
	}

	@discardableResult
	public mutating func lock(at point: CGPoint) -> CGPoint {
		if case .locked(let existing) = self { return existing }
		if case .frozen(let existing) = self { return existing }
		self = .locked(anchor: point)
		return point
	}

	public mutating func freeze() {
		guard case .locked(let anchor) = self else { return }
		self = .frozen(anchor: anchor)
	}

	public mutating func unfreeze() {
		guard case .frozen(let anchor) = self else { return }
		self = .locked(anchor: anchor)
	}

	public mutating func refresh(to point: CGPoint) {
		guard case .locked = self else { return }
		self = .locked(anchor: point)
	}

	public mutating func release() {
		self = .idle
	}
}
