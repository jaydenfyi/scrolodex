import CoreGraphics

public enum GestureTouchPhase: Sendable {
	case began
	case moved
	case stationary
	case ended
	case cancelled
}

public struct GestureTouch: Equatable, Sendable {
	public let identity: String
	public let phase: GestureTouchPhase
	public let normalizedPosition: CGPoint
	public let isResting: Bool

	public init(identity: String, phase: GestureTouchPhase, normalizedPosition: CGPoint, isResting: Bool) {
		self.identity = identity
		self.phase = phase
		self.normalizedPosition = normalizedPosition
		self.isResting = isResting
	}

	public var isDown: Bool {
		!isResting && (phase == .began || phase == .moved || phase == .stationary)
	}
}

public enum GestureTouchSnapshot: Sendable {
	public static func isTerminal(_ touches: [GestureTouch]) -> Bool {
		touches.isEmpty || !touches.contains(where: \.isDown)
	}

	public static func exceedsFingerCount(_ touches: [GestureTouch], configuredFingerCount: Int) -> Bool {
		touches.filter(\.isDown).count > configuredFingerCount
	}
}

public struct GestureTouchTracker: Sendable {
	private var startPositions: [String: CGPoint] = [:]
	private var downTouchIDs: Set<String> = []

	public init() {}

	public func hasRecordedStart() -> Bool { !startPositions.isEmpty }

	public var hasDownTouches: Bool { !downTouchIDs.isEmpty }

	public mutating func updateDownTouches(_ touches: [GestureTouch]) {
		for touch in touches {
			if touch.isDown {
				downTouchIDs.insert(touch.identity)
			} else {
				downTouchIDs.remove(touch.identity)
			}
		}
	}

	public mutating func recordStart(_ touches: [GestureTouch]) -> Bool {
		let hasNew = touches.contains { startPositions[$0.identity] == nil }
		if hasNew {
			for touch in touches {
				startPositions[touch.identity] = touch.normalizedPosition
			}
		}
		return hasNew
	}

	public func swipeDelta(_ touches: [GestureTouch]) -> (dx: CGFloat, dy: CGFloat) {
		var totalX: CGFloat = 0
		var totalY: CGFloat = 0
		var count: CGFloat = 0
		for touch in touches {
			if let start = startPositions[touch.identity] {
				let current = touch.normalizedPosition
				totalX += current.x - start.x
				totalY += current.y - start.y
				count += 1
			}
		}
		guard count > 0 else { return (dx: 0, dy: 0) }
		return (dx: totalX / count, dy: totalY / count)
	}

	public mutating func resetAxis(_ touches: [GestureTouch], horizontal: Bool) {
		for touch in touches {
			guard var position = startPositions[touch.identity] else { continue }
			if horizontal {
				position.x = touch.normalizedPosition.x
			} else {
				position.y = touch.normalizedPosition.y
			}
			startPositions[touch.identity] = position
		}
	}

	public mutating func reset() {
		startPositions.removeAll(keepingCapacity: true)
		downTouchIDs.removeAll(keepingCapacity: true)
	}
}
