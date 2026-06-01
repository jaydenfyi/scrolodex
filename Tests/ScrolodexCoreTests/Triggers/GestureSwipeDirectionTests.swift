import CoreGraphics
import Testing

@testable import ScrolodexCore

@Suite("gesture swipe direction")
struct GestureSwipeDirectionTests {
	@Test("vertical direction ignores horizontal-only deltas")
	func verticalDirectionIgnoresHorizontalOnlyDeltas() {
		let result = GestureSwipeDirection.vertical.navigationDelta(
			dx: 0.08,
			dy: 0.0,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .undecided)

		#expect(result.intent == .horizontal)
		#expect(result.navigation == nil)
	}

	@Test("vertical direction accepts vertical deltas even when horizontal is larger")
	func verticalDirectionAcceptsVerticalDeltasEvenWhenHorizontalIsLarger() {
		let result = GestureSwipeDirection.vertical.navigationDelta(
			dx: 0.08,
			dy: -0.04,
			threshold: 0.03,
			dominanceRatio: 3.0,
			currentIntent: .undecided)

		#expect(result.intent == .vertical)
		#expect(result.navigation == GestureSwipeNavigationDelta(axis: .vertical, direction: -1))
	}

	@Test("horizontal direction ignores vertical-only deltas")
	func horizontalDirectionIgnoresVerticalOnlyDeltas() {
		let result = GestureSwipeDirection.horizontal.navigationDelta(
			dx: 0.0,
			dy: 0.08,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .undecided)

		#expect(result.intent == .vertical)
		#expect(result.navigation == nil)
	}

	@Test("both directions preserve dominant axis behavior")
	func bothDirectionsPreserveDominantAxisBehavior() {
		let result = GestureSwipeDirection.both.navigationDelta(
			dx: 0.08,
			dy: 0.04,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .undecided)

		#expect(result.intent == .horizontal)
		#expect(result.navigation == GestureSwipeNavigationDelta(axis: .horizontal, direction: -1))
	}

	@Test("vertical direction locks horizontal intent when horizontal motion dominates")
	func verticalDirectionLocksHorizontalIntentWhenHorizontalMotionDominates() {
		let result = GestureSwipeDirection.vertical.navigationDelta(
			dx: 0.22,
			dy: 0.04,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .undecided)

		#expect(result.intent == .horizontal)
		#expect(result.navigation == nil)
	}

	@Test("vertical direction suppresses navigation after horizontal intent locks")
	func verticalDirectionSuppressesNavigationAfterHorizontalIntentLocks() {
		let result = GestureSwipeDirection.vertical.navigationDelta(
			dx: 0.22,
			dy: 0.12,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .horizontal)

		#expect(result.intent == .horizontal)
		#expect(result.navigation == nil)
	}

	@Test("deltas below threshold do not navigate")
	func deltasBelowThresholdDoNotNavigate() {
		let result = GestureSwipeDirection.vertical.navigationDelta(
			dx: 0.0,
			dy: 0.02,
			threshold: 0.03,
			dominanceRatio: 1.5,
			currentIntent: .undecided)

		#expect(result.intent == .undecided)
		#expect(result.navigation == nil)
	}
}
