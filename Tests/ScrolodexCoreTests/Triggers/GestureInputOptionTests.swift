import Testing

@testable import ScrolodexCore

@Suite("Gesture input option")
struct GestureInputOptionTests {
	@Test("options expose the four supported gesture choices")
	func supportedOptions() {
		#expect(GestureInputOption.allCases.map(\.displayName) == [
			"None",
			"Swipe Up or Down with Three Fingers",
			"Swipe Left or Right with Three Fingers",
			"Swipe Up or Down with Four Fingers",
			"Swipe Left or Right with Four Fingers",
		])
	}

	@Test("option maps to finger count and direction")
	func mapsToGestureSettings() {
		let option = GestureInputOption.fourFingerHorizontal

		#expect(option.fingerCount == .four)
		#expect(option.swipeDirection == .horizontal)
	}

	@Test("option resolves from stored finger count and direction")
	func resolvesFromStoredSettings() {
		let option = GestureInputOption(fingerCountRawValue: 3, swipeDirectionRawValue: "horizontal")

		#expect(option == .threeFingerHorizontal)
	}

	@Test("invalid direction falls back to vertical")
	func invalidDirectionFallsBackToVertical() {
		let option = GestureInputOption(fingerCountRawValue: 4, swipeDirectionRawValue: "diagonal")

		#expect(option == .fourFingerVertical)
	}
}
