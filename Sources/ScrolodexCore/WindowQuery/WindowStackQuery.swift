import CoreGraphics

public struct WindowStackQuery: Equatable, Sendable {
	public let scope: TriggerScope
	public let filter: TriggerFilter
	public let monitorScope: MonitorScope
	public let cursor: CGPoint
	public let bundleID: String?

	public init(
		scope: TriggerScope,
		filter: TriggerFilter,
		monitorScope: MonitorScope,
		cursor: CGPoint,
		bundleID: String? = nil
	) {
		self.scope = scope
		self.filter = filter
		self.monitorScope = monitorScope
		self.cursor = cursor
		self.bundleID = bundleID
	}
}
