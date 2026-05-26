import AppKit
import ScrolodexCore

extension OverlayTheme {
	@MainActor
	var resolved: ResolvedTheme {
		switch self {
		case .system:
			let name = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) ?? .aqua
			return name == .darkAqua ? .dark : .light
		case .light:
			return .light
		case .dark:
			return .dark
		}
	}
}
