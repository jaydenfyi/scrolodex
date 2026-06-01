public enum GestureInputOption: String, CaseIterable, Equatable, Sendable {
	case none
	case threeFingerVertical
	case threeFingerHorizontal
	case fourFingerVertical
	case fourFingerHorizontal

	public init(fingerCountRawValue: Int, swipeDirectionRawValue: String?) {
		guard let fingerCount = TrackpadFingerCount(rawValue: fingerCountRawValue) else {
			self = .none
			return
		}

		let swipeDirection = GestureSwipeDirection(rawValue: swipeDirectionRawValue ?? "") ?? .vertical
		switch (fingerCount, swipeDirection) {
		case (.three, .horizontal): self = .threeFingerHorizontal
		case (.three, _): self = .threeFingerVertical
		case (.four, .horizontal): self = .fourFingerHorizontal
		case (.four, _): self = .fourFingerVertical
		}
	}

	public var fingerCount: TrackpadFingerCount? {
		switch self {
		case .none: nil
		case .threeFingerVertical, .threeFingerHorizontal: .three
		case .fourFingerVertical, .fourFingerHorizontal: .four
		}
	}

	public var swipeDirection: GestureSwipeDirection {
		switch self {
		case .threeFingerHorizontal, .fourFingerHorizontal: .horizontal
		case .none, .threeFingerVertical, .fourFingerVertical: .vertical
		}
	}

	public var displayName: String {
		switch self {
		case .none: "None"
		case .threeFingerVertical: "Swipe Up or Down with Three Fingers"
		case .threeFingerHorizontal: "Swipe Left or Right with Three Fingers"
		case .fourFingerVertical: "Swipe Up or Down with Four Fingers"
		case .fourFingerHorizontal: "Swipe Left or Right with Four Fingers"
		}
	}
}
