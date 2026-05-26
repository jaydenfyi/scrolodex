public enum NavigationOutcome: Equatable {
	case confirmed(WindowCandidate)
	case canceled
}

public enum SelectionMovement: Equatable, Sendable {
	case none
	case changed(direction: Int, wrapped: Bool)

	public var transitionDirection: Int {
		switch self {
		case .none:
			0
		case let .changed(direction, wrapped):
			wrapped ? 0 : direction
		}
	}
}

public enum ScrollSensitivity {
	public static let `default`: Double = 6
}

public struct NavigationSession {
	public private(set) var isActive = true

	private let candidates: [WindowCandidate]
	private let scrollThreshold: Double
	private let wrapAround: Bool
	private var selectedIndex = 0
	private var accumulatedDelta = 0.0

	public var selectedCandidate: WindowCandidate {
		candidates[selectedIndex]
	}

	public init(candidates: [WindowCandidate], scrollThreshold: Double, wrapAround: Bool = true) {
		precondition(!candidates.isEmpty, "NavigationSession requires at least one candidate")
		precondition(scrollThreshold > 0, "scrollThreshold must be positive")
		self.candidates = candidates
		self.scrollThreshold = scrollThreshold
		self.wrapAround = wrapAround
	}

	private func nextIndex(from index: Int, direction: Int) -> Int {
		let raw = index + direction
		if wrapAround {
			return (raw + candidates.count) % candidates.count
		}
		return min(max(raw, 0), candidates.count - 1)
	}

	private func wraps(from index: Int, direction: Int) -> Bool {
		guard wrapAround else { return false }
		return index + direction < 0 || index + direction >= candidates.count
	}

	private func wouldChange(from index: Int, direction: Int) -> Bool {
		nextIndex(from: index, direction: direction) != index
	}

	public mutating func applyScrollDelta(_ delta: Double) -> SelectionMovement {
		guard isActive else { return .none }

		accumulatedDelta += delta

		if accumulatedDelta >= scrollThreshold {
			let direction = 1
			accumulatedDelta = 0
			guard wouldChange(from: selectedIndex, direction: direction) else { return .none }
			let wrapped = wraps(from: selectedIndex, direction: direction)
			selectedIndex = nextIndex(from: selectedIndex, direction: direction)
			return .changed(direction: direction, wrapped: wrapped)
		}

		if accumulatedDelta <= -scrollThreshold {
			let direction = -1
			accumulatedDelta = 0
			guard wouldChange(from: selectedIndex, direction: direction) else { return .none }
			let wrapped = wraps(from: selectedIndex, direction: direction)
			selectedIndex = nextIndex(from: selectedIndex, direction: direction)
			return .changed(direction: direction, wrapped: wrapped)
		}

		return .none
	}

	public mutating func step(direction: Int) -> SelectionMovement {
		guard isActive, direction != 0 else { return .none }
		let normalized = direction > 0 ? 1 : -1
		guard wouldChange(from: selectedIndex, direction: normalized) else { return .none }
		let wrapped = wraps(from: selectedIndex, direction: normalized)
		selectedIndex = nextIndex(from: selectedIndex, direction: normalized)
		return .changed(direction: normalized, wrapped: wrapped)
	}

	public mutating func confirm() -> NavigationOutcome {
		isActive = false
		return .confirmed(selectedCandidate)
	}
}
