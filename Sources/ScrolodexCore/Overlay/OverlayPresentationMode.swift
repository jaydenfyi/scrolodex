public enum OverlayPresentationMode: String, CaseIterable, Sendable {
	case none
	case tooltip
	case list
	case tile

	public static let `default`: OverlayPresentationMode = .tooltip

	public var displayName: String {
		switch self {
		case .none: "None"
		case .tooltip: "Tooltip"
		case .list: "List"
		case .tile: "Tile"
		}
	}
}
