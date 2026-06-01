import CoreGraphics
import Testing

@testable import ScrolodexCore

@Suite("gesture touch tracker")
struct GestureTouchTrackerTests {
	@Test("down touches include stationary fingers during swipe")
	func downTouchesIncludeStationaryFingersDuringSwipe() {
		let touches = [
			makeTouch("a", phase: .moved),
			makeTouch("b", phase: .stationary),
			makeTouch("c", phase: .stationary),
			makeTouch("d", phase: .ended),
		]

		#expect(touches.filter(\.isDown).map(\.identity).sorted() == ["a", "b", "c"])
	}

	@Test("tracker records a three-finger swipe when only one finger moved")
	func trackerRecordsThreeFingerSwipeWhenOnlyOneFingerMoved() {
		var tracker = GestureTouchTracker()
		let start = [
			makeTouch("a", phase: .began, position: CGPoint(x: 0.2, y: 0.5)),
			makeTouch("b", phase: .began, position: CGPoint(x: 0.4, y: 0.5)),
			makeTouch("c", phase: .began, position: CGPoint(x: 0.6, y: 0.5)),
		]
		let recorded = tracker.recordStart(start)
		#expect(recorded)

		let moved = [
			makeTouch("a", phase: .moved, position: CGPoint(x: 0.29, y: 0.5)),
			makeTouch("b", phase: .stationary, position: CGPoint(x: 0.49, y: 0.5)),
			makeTouch("c", phase: .stationary, position: CGPoint(x: 0.69, y: 0.5)),
		]

		#expect(tracker.swipeDelta(moved).dx > 0.08)
	}

	@Test("empty touch snapshots are terminal")
	func emptyTouchSnapshotsAreTerminal() {
		#expect(GestureTouchSnapshot.isTerminal([]))
	}

	@Test("partial lift events keep remaining tracked fingers down")
	func partialLiftEventsKeepRemainingTrackedFingersDown() {
		var tracker = GestureTouchTracker()
		tracker.updateDownTouches([
			makeTouch("a", phase: .began),
			makeTouch("b", phase: .began),
			makeTouch("c", phase: .began),
		])

		tracker.updateDownTouches([makeTouch("a", phase: .ended)])

		#expect(tracker.hasDownTouches)
	}

	@Test("all lifted tracked fingers end the session")
	func allLiftedTrackedFingersEndTheSession() {
		var tracker = GestureTouchTracker()
		tracker.updateDownTouches([
			makeTouch("a", phase: .began),
			makeTouch("b", phase: .began),
		])

		tracker.updateDownTouches([
			makeTouch("a", phase: .ended),
			makeTouch("b", phase: .ended),
		])

		#expect(!tracker.hasDownTouches)
	}

	@Test("extra fingers exceed active gesture finger count")
	func extraFingersExceedActiveGestureFingerCount() {
		let touches = [
			makeTouch("a", phase: .moved),
			makeTouch("b", phase: .moved),
			makeTouch("c", phase: .stationary),
			makeTouch("d", phase: .began),
		]

		#expect(GestureTouchSnapshot.exceedsFingerCount(touches, configuredFingerCount: 3))
		#expect(!GestureTouchSnapshot.exceedsFingerCount(touches, configuredFingerCount: 4))
	}

	private func makeTouch(
		_ identity: String,
		phase: GestureTouchPhase,
		position: CGPoint = CGPoint(x: 0.5, y: 0.5),
		isResting: Bool = false
	) -> GestureTouch {
		GestureTouch(identity: identity, phase: phase, normalizedPosition: position, isResting: isResting)
	}
}
