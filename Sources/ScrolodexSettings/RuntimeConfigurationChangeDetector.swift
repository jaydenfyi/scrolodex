public struct RuntimeConfigurationChangeDetector: Sendable {
	private var current: RuntimeConfiguration

	public init(current: RuntimeConfiguration) {
		self.current = current
	}

	public mutating func updateIfChanged(_ next: RuntimeConfiguration) -> Bool {
		guard next != current else { return false }
		current = next
		return true
	}
}
