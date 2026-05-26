public enum PeekPresentationPolicy {
	public static func usesBorderOnly(scope: TriggerScope, isInitialSelection: Bool) -> Bool {
		isInitialSelection && scope != .dockHover
	}
}
