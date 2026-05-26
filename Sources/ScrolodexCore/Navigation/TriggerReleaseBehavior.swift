public enum TriggerReleaseAction: Equatable, Sendable {
	case confirm
	case none
}

public enum TriggerReleaseBehavior {
	public static func action(hasActiveSession: Bool) -> TriggerReleaseAction {
		hasActiveSession ? .confirm : .none
	}
}
