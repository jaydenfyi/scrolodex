import CoreGraphics

public enum OverlayTheme: String, CaseIterable, Sendable {
	case system
	case light
	case dark

	public static let `default`: OverlayTheme = .system

	public var displayName: String {
		switch self {
		case .system: "System"
		case .dark: "Dark"
		case .light: "Light"
		}
	}
}

public enum ResolvedTheme: Sendable {
	case light
	case dark

	public static let `default`: ResolvedTheme = .light
}

public struct OverlayColorTokens: Sendable {
	public let background: TokenColor
	public let border: TokenColor
	public let primaryText: TokenColor
	public let subtitleText: TokenColor
	public let selectedFill: TokenColor
	public let selectedStroke: TokenColor
	public let unselectedFill: TokenColor
	public let thumbnailBackground: TokenColor
	public let thumbnailBorder: TokenColor
	public let noPreviewText: TokenColor
	public let badgeBackground: TokenColor
	public let badgeBorder: TokenColor
	public let peekBorder: TokenColor

	public init(
		background: TokenColor,
		border: TokenColor,
		primaryText: TokenColor,
		subtitleText: TokenColor,
		selectedFill: TokenColor,
		selectedStroke: TokenColor,
		unselectedFill: TokenColor,
		thumbnailBackground: TokenColor,
		thumbnailBorder: TokenColor,
		noPreviewText: TokenColor,
		badgeBackground: TokenColor,
		badgeBorder: TokenColor,
		peekBorder: TokenColor
	) {
		self.background = background
		self.border = border
		self.primaryText = primaryText
		self.subtitleText = subtitleText
		self.selectedFill = selectedFill
		self.selectedStroke = selectedStroke
		self.unselectedFill = unselectedFill
		self.thumbnailBackground = thumbnailBackground
		self.thumbnailBorder = thumbnailBorder
		self.noPreviewText = noPreviewText
		self.badgeBackground = badgeBackground
		self.badgeBorder = badgeBorder
		self.peekBorder = peekBorder
	}

	public static func tokens(for theme: ResolvedTheme) -> OverlayColorTokens {
		switch theme {
		case .dark: darkTokens
		case .light: lightTokens
		}
	}

	private static let darkTokens = OverlayColorTokens(
		background: TokenColor(red: 0.045, green: 0.047, blue: 0.055, alpha: 0.93),
		border: TokenColor(white: 1.0, alpha: 0.16),
		primaryText: TokenColor(white: 1.0, alpha: 1.0),
		subtitleText: TokenColor(white: 1.0, alpha: 0.58),
		selectedFill: TokenColor(red: 0.18, green: 0.32, blue: 0.95, alpha: 0.34),
		selectedStroke: TokenColor(red: 0.60, green: 0.70, blue: 1.0, alpha: 0.58),
		unselectedFill: TokenColor(white: 1.0, alpha: 0.055),
		thumbnailBackground: TokenColor(white: 0.0, alpha: 0.30),
		thumbnailBorder: TokenColor(white: 1.0, alpha: 0.12),
		noPreviewText: TokenColor(white: 1.0, alpha: 0.52),
		badgeBackground: TokenColor(white: 0.0, alpha: 0.88),
		badgeBorder: TokenColor(white: 1.0, alpha: 0.28),
		peekBorder: TokenColor(red: 0.62, green: 0.72, blue: 1.0, alpha: 0.82)
	)

	private static let lightTokens = OverlayColorTokens(
		background: TokenColor(red: 0.965, green: 0.965, blue: 0.965, alpha: 0.95),
		border: TokenColor(white: 1.0, alpha: 0.0),
		primaryText: TokenColor(red: 0.114, green: 0.114, blue: 0.122, alpha: 1.0),
		subtitleText: TokenColor(white: 0.0, alpha: 0.50),
		selectedFill: TokenColor(white: 0.0, alpha: 0.12),
		selectedStroke: TokenColor(white: 0.0, alpha: 0.0),
		unselectedFill: TokenColor(white: 0.0, alpha: 0.03),
		thumbnailBackground: TokenColor(white: 0.0, alpha: 0.05),
		thumbnailBorder: TokenColor(white: 0.0, alpha: 0.08),
		noPreviewText: TokenColor(white: 0.0, alpha: 0.28),
		badgeBackground: TokenColor(red: 0.965, green: 0.965, blue: 0.965, alpha: 0.95),
		badgeBorder: TokenColor(white: 1.0, alpha: 0.0),
		peekBorder: TokenColor(red: 0.0, green: 0.39, blue: 1.0, alpha: 0.52)
	)
}

public struct TokenColor: Sendable {
	public let red: CGFloat
	public let green: CGFloat
	public let blue: CGFloat
	public let alpha: CGFloat

	public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}

	public init(white: CGFloat, alpha: CGFloat) {
		self.init(red: white, green: white, blue: white, alpha: alpha)
	}
}
