import AppKit
import CoreGraphics
import ScrolodexCore

@MainActor
final class CGWindowStackProvider: WindowStackProviding {
	private let excludedOwnerNames: Set<String> = ["Scrolodex", "Dock", "Window Server"]

	func candidates(matching query: WindowStackQuery) -> [WindowCandidate] {
		switch query.scope {
		case .underCursor:
			if query.filter == .sameApp {
				return sameAppUnderCursor(query.cursor)
			}
			return candidatesUnderCursor(query.cursor)
		case .currentScreen:
			if query.filter == .sameApp {
				return sameAppOnScreen(monitorScope: query.monitorScope, near: query.cursor)
			}
			return allCandidatesOnScreen(monitorScope: query.monitorScope, near: query.cursor)
		case .dockHover:
			guard let bundleID = query.bundleID else { return [] }
			return windowsForApp(
				bundleIdentifier: bundleID, monitorScope: query.monitorScope, near: query.cursor)
		}
	}

	static func currentCursorLocationForCGWindows() -> CGPoint {
		let location = NSEvent.mouseLocation
		guard let screen = NSScreen.screens.first else { return location }
		return CGPoint(x: location.x, y: screen.frame.height - location.y)
	}

	private func candidatesUnderCursor(_ cursor: CGPoint) -> [WindowCandidate] {
		let (rawCount, candidates) = fetchAllCandidates()
		let filtered = WindowStackFilter.candidates(
			from: candidates,
			under: cursor,
			excludingOwnerNames: excludedOwnerNames
		)
		Log.debug(
			"window scan cursor=%@ raw=%d parsed=%d filtered=%d", NSStringFromPoint(cursor),
			rawCount, candidates.count, filtered.count)
		return filtered
	}

	private func allCandidatesOnScreen(monitorScope: MonitorScope, near cursor: CGPoint) -> [WindowCandidate] {
		let (_, candidates) = fetchAllCandidates()
		let screenBounds = Self.screenBounds(containing: cursor)
		let filtered = WindowStackFilter.allWindows(
			from: candidates,
			monitorScope: monitorScope,
			screenBounds: screenBounds,
			excludingOwnerNames: excludedOwnerNames
		)
		Log.debug(
			"all windows scan cursor=%@ monitorScope=%@ screen=%@ parsed=%d filtered=%d",
			NSStringFromPoint(cursor), monitorScope.rawValue, NSStringFromRect(screenBounds),
			candidates.count, filtered.count)
		return filtered
	}

	private func sameAppUnderCursor(_ cursor: CGPoint) -> [WindowCandidate] {
		let (_, candidates) = fetchAllCandidates()
		let cursorFiltered = WindowStackFilter.candidates(
			from: candidates,
			under: cursor,
			excludingOwnerNames: excludedOwnerNames
		)
		guard let topApp = cursorFiltered.first?.ownerName else { return [] }
		let filtered = WindowStackFilter.sameApp(
			from: candidates,
			appName: topApp,
			under: cursor,
			excludingOwnerNames: excludedOwnerNames
		)
		Log.debug(
			"same app under cursor app=%@ cursor=%@ filtered=%d", topApp, NSStringFromPoint(cursor),
			filtered.count)
		return filtered
	}

	private func sameAppOnScreen(monitorScope: MonitorScope, near cursor: CGPoint) -> [WindowCandidate] {
		let (_, candidates) = fetchAllCandidates()
		let screenBounds = Self.screenBounds(containing: cursor)
		let screenFiltered = WindowStackFilter.allWindows(
			from: candidates,
			monitorScope: monitorScope,
			screenBounds: screenBounds,
			excludingOwnerNames: excludedOwnerNames
		)
		guard let topApp = Self.topmostApp(at: cursor, from: candidates) else { return [] }
		let filtered = screenFiltered.filter {
			$0.ownerName == topApp && !excludedOwnerNames.contains($0.ownerName)
		}
		Log.debug(
			"same app on screen app=%@ cursor=%@ filtered=%d", topApp, NSStringFromPoint(cursor),
			filtered.count)
		return filtered
	}

	private func windowsForApp(
		bundleIdentifier: String, monitorScope: MonitorScope, near cursor: CGPoint
	) -> [WindowCandidate] {
		let pids = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).map(
			\.processIdentifier)
		guard !pids.isEmpty else { return [] }

		let (_, candidates) = fetchAllCandidates()
		let filtered = WindowStackFilter.appWindows(
			from: candidates,
			ownerPIDs: Set(pids),
			monitorScope: monitorScope,
			screenBounds: Self.screenBounds(containing: cursor),
			excludingOwnerNames: excludedOwnerNames
		)
		Log.debug(
			"windows for app bundle=%@ monitorScope=%@ pids=%@ count=%d", bundleIdentifier,
			monitorScope.rawValue, String(describing: pids), filtered.count)
		return filtered
	}

	private static func screenBounds(containing cgPoint: CGPoint) -> CGRect {
		let screens = NSScreen.screens
		let primaryHeight = screens.first?.frame.height ?? 0
		let appKitPoint = CGPoint(x: cgPoint.x, y: primaryHeight - cgPoint.y)

		let matchedScreen = screens.first { $0.frame.contains(appKitPoint) } ?? screens.first
		guard let screen = matchedScreen else { return .null }

		let frame = screen.frame
		return CGRect(
			x: frame.origin.x, y: primaryHeight - frame.origin.y - frame.height, width: frame.width,
			height: frame.height)
	}

	private static func topmostApp(at cursor: CGPoint, from candidates: [WindowCandidate]) -> String? {
		candidates.first(where: { candidate in
			candidate.layer <= 20
				&& candidate.alpha > 0
				&& candidate.bounds.width > 0
				&& candidate.bounds.height > 0
				&& candidate.bounds.contains(cursor)
		})?.ownerName
	}

	private func fetchAllCandidates() -> (rawCount: Int, candidates: [WindowCandidate]) {
		let rawWindows =
			CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
			as? [[String: Any]] ?? []
		let candidates = rawWindows.compactMap(CGWindowDictionaryParser.candidate(from:)).map(
			enrichTitleIfNeeded)
		return (rawWindows.count, candidates)
	}

	private func enrichTitleIfNeeded(_ candidate: WindowCandidate) -> WindowCandidate {
		if let title = candidate.windowTitle, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return candidate
		}

		guard let axTitle = AXWindowAccessor.readTitle(for: candidate) else { return candidate }
		return WindowCandidate(
			cgWindowID: candidate.cgWindowID,
			ownerPID: candidate.ownerPID,
			ownerName: candidate.ownerName,
			windowTitle: axTitle,
			bounds: candidate.bounds,
			layer: candidate.layer,
			alpha: candidate.alpha
		)
	}
}
