import CoreGraphics
import ScrolodexCore
import Testing

@Suite("gesture cursor lock state")
struct GestureCursorLockStateTests {
	@Test("lock keeps the initial anchor until released")
	func lockKeepsInitialAnchorUntilReleased() {
		var state = GestureCursorLockState()
		let initial = CGPoint(x: 100, y: 200)
		let later = CGPoint(x: 120, y: 240)

		#expect(state.lock(at: initial) == initial)
		#expect(state.lock(at: later) == initial)
		#expect(state.anchor == initial)

		state.release()

		#expect(state.anchor == nil)
	}

	@Test("refresh updates an existing anchor")
	func refreshUpdatesExistingAnchor() {
		var state = GestureCursorLockState(anchor: CGPoint(x: 100, y: 200))
		let current = CGPoint(x: 160, y: 260)

		state.refresh(to: current)

		#expect(state.anchor == current)
	}
}
