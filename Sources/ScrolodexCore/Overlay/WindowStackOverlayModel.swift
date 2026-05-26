import CoreGraphics
import Foundation

public struct WindowStackOverlayModel: Equatable, Sendable {
	public struct Row: Equatable, Sendable {
		public let windowID: CGWindowID
		public let primaryText: String
		public let secondaryText: String
		public let isSelected: Bool

		public init(windowID: CGWindowID, primaryText: String, secondaryText: String, isSelected: Bool) {
			self.windowID = windowID
			self.primaryText = primaryText
			self.secondaryText = secondaryText
			self.isSelected = isSelected
		}
	}

	public let title: String
	public let subtitle: String
	public let rows: [Row]
	public let selectedIndex: Int

	public init(candidates: [WindowCandidate], selected: WindowCandidate?, scope: TriggerScope = .underCursor) {
		if candidates.isEmpty {
			title = "No Windows Here"
			subtitle =
				scope == .underCursor
				? "Move over overlapping windows, then scroll"
				: "No windows found on this screen"
			rows = []
			selectedIndex = 0
			return
		}

		title = "Choose Window"
		let location = scope == .underCursor ? "under cursor" : "on screen"
		subtitle = "\(candidates.count) window\(candidates.count == 1 ? "" : "s") \(location)"
		selectedIndex = selected.flatMap { candidates.firstIndex(of: $0) } ?? 0
		rows = candidates.map { candidate in
			let title = candidate.windowTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
			let primary = title.flatMap { $0.isEmpty ? nil : $0 } ?? candidate.ownerName
			return Row(
				windowID: candidate.cgWindowID,
				primaryText: primary,
				secondaryText: "\(candidate.ownerName) • Window #\(candidate.cgWindowID)",
				isSelected: candidate == selected
			)
		}
	}
}
