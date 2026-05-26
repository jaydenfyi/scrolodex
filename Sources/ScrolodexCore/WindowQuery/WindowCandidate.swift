import CoreGraphics

public struct WindowCandidate: Equatable, Sendable {
	public let cgWindowID: CGWindowID
	public let ownerPID: pid_t
	public let ownerName: String
	public let windowTitle: String?
	public let bounds: CGRect
	public let layer: Int
	public let alpha: Double

	public init(
		cgWindowID: CGWindowID,
		ownerPID: pid_t,
		ownerName: String,
		windowTitle: String?,
		bounds: CGRect,
		layer: Int,
		alpha: Double
	) {
		self.cgWindowID = cgWindowID
		self.ownerPID = ownerPID
		self.ownerName = ownerName
		self.windowTitle = windowTitle
		self.bounds = bounds
		self.layer = layer
		self.alpha = alpha
	}
}
