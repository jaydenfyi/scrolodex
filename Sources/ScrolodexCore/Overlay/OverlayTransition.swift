public enum OverlayTransition {
	public enum Axis {
		case vertical
		case horizontal
	}

	public static func initialOffset(for direction: Int, axis: Axis) -> Double {
		guard direction != 0 else { return 0 }
		let normalized = direction > 0 ? 1.0 : -1.0
		switch axis {
		case .vertical:
			return -normalized
		case .horizontal:
			return normalized
		}
	}
}
