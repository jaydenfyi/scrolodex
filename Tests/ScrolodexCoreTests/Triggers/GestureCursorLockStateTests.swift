import CoreGraphics
import ScrolodexCore
import Testing

@Suite("gesture cursor lock state")
struct GestureCursorLockStateTests {
	@Test("lock transitions idle to locked")
	func lockTransitionsIdleToLocked() {
		var state = GestureCursorLockState()
		let point = CGPoint(x: 100, y: 200)

		_ = state.lock(at: point)

		#expect(state == .locked(anchor: point))
		#expect(state.anchor == point)
	}

	@Test("lock keeps first anchor on repeated calls")
	func lockKeepsFirstAnchor() {
		var state = GestureCursorLockState()
		let initial = CGPoint(x: 100, y: 200)
		let later = CGPoint(x: 120, y: 240)

		#expect(state.lock(at: initial) == initial)
		#expect(state.lock(at: later) == initial)
		#expect(state.anchor == initial)
	}

	@Test("lock is no-op on frozen state")
	func lockIsNoOpOnFrozen() {
		var state = GestureCursorLockState.locked(anchor: CGPoint(x: 100, y: 200))
		state.freeze()

		let result = state.lock(at: CGPoint(x: 300, y: 400))

		#expect(result == CGPoint(x: 100, y: 200))
		#expect(state == .frozen(anchor: CGPoint(x: 100, y: 200)))
	}

	@Test("freeze transitions locked to frozen")
	func freezeTransitionsLockedToFrozen() {
		var state = GestureCursorLockState.locked(anchor: CGPoint(x: 100, y: 200))

		state.freeze()

		#expect(state == .frozen(anchor: CGPoint(x: 100, y: 200)))
		#expect(state.isFrozen == true)
	}

	@Test("freeze is no-op on idle")
	func freezeIsNoOpOnIdle() {
		var state = GestureCursorLockState()

		state.freeze()

		#expect(state == .idle)
	}

	@Test("freeze is no-op when already frozen")
	func freezeIsNoOpWhenAlreadyFrozen() {
		var state = GestureCursorLockState.frozen(anchor: CGPoint(x: 100, y: 200))

		state.freeze()

		#expect(state == .frozen(anchor: CGPoint(x: 100, y: 200)))
	}

	@Test("unfreeze transitions frozen to locked")
	func unfreezeTransitionsFrozenToLocked() {
		var state = GestureCursorLockState.frozen(anchor: CGPoint(x: 100, y: 200))

		state.unfreeze()

		#expect(state == .locked(anchor: CGPoint(x: 100, y: 200)))
		#expect(state.isFrozen == false)
	}

	@Test("unfreeze is no-op on idle")
	func unfreezeIsNoOpOnIdle() {
		var state = GestureCursorLockState()

		state.unfreeze()

		#expect(state == .idle)
	}

	@Test("unfreeze is no-op on locked")
	func unfreezeIsNoOpOnLocked() {
		var state = GestureCursorLockState.locked(anchor: CGPoint(x: 100, y: 200))

		state.unfreeze()

		#expect(state == .locked(anchor: CGPoint(x: 100, y: 200)))
	}

	@Test("refresh updates anchor in locked state")
	func refreshUpdatesAnchorInLocked() {
		var state = GestureCursorLockState.locked(anchor: CGPoint(x: 100, y: 200))
		let updated = CGPoint(x: 160, y: 260)

		state.refresh(to: updated)

		#expect(state == .locked(anchor: updated))
	}

	@Test("refresh is no-op on idle")
	func refreshIsNoOpOnIdle() {
		var state = GestureCursorLockState()

		state.refresh(to: CGPoint(x: 100, y: 200))

		#expect(state == .idle)
	}

	@Test("refresh is no-op on frozen")
	func refreshIsNoOpOnFrozen() {
		var state = GestureCursorLockState.frozen(anchor: CGPoint(x: 100, y: 200))

		state.refresh(to: CGPoint(x: 999, y: 999))

		#expect(state == .frozen(anchor: CGPoint(x: 100, y: 200)))
	}

	@Test("release transitions locked to idle")
	func releaseTransitionsLockedToIdle() {
		var state = GestureCursorLockState.locked(anchor: CGPoint(x: 100, y: 200))

		state.release()

		#expect(state == .idle)
		#expect(state.anchor == nil)
	}

	@Test("release transitions frozen to idle")
	func releaseTransitionsFrozenToIdle() {
		var state = GestureCursorLockState.frozen(anchor: CGPoint(x: 100, y: 200))

		state.release()

		#expect(state == .idle)
		#expect(state.anchor == nil)
	}

	@Test("release is no-op on idle")
	func releaseIsNoOpOnIdle() {
		var state = GestureCursorLockState()

		state.release()

		#expect(state == .idle)
	}

	@Test("isFrozen is false for idle and locked")
	func isFrozenFalseForIdleAndLocked() {
		#expect(GestureCursorLockState().isFrozen == false)
		#expect(GestureCursorLockState.locked(anchor: .zero).isFrozen == false)
	}

	@Test("anchor is nil only in idle")
	func anchorNilOnlyInIdle() {
		let point = CGPoint(x: 50, y: 75)
		#expect(GestureCursorLockState().anchor == nil)
		#expect(GestureCursorLockState.locked(anchor: point).anchor == point)
		#expect(GestureCursorLockState.frozen(anchor: point).anchor == point)
	}

	@Test("full lifecycle: idle → locked → frozen → locked → idle")
	func fullLifecycle() {
		var state = GestureCursorLockState()
		let point = CGPoint(x: 100, y: 200)

		state.lock(at: point)
		#expect(state == .locked(anchor: point))

		state.freeze()
		#expect(state == .frozen(anchor: point))

		state.unfreeze()
		#expect(state == .locked(anchor: point))

		state.release()
		#expect(state == .idle)
	}
}
