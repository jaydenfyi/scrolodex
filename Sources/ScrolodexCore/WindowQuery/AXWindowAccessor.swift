import ApplicationServices
import CoreGraphics

@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

public struct AXWindowSnapshot: Equatable, Sendable {
	public let cgWindowID: CGWindowID?
	public let title: String?
	public let bounds: CGRect?

	public init(cgWindowID: CGWindowID?, title: String?, bounds: CGRect?) {
		self.cgWindowID = cgWindowID
		self.title = title
		self.bounds = bounds
	}
}

public enum AXWindowAccessor {
	public static func findWindow(for candidate: WindowCandidate, in appElement: AXUIElement) -> AXUIElement? {
		guard let windows = copyAttribute(kAXWindowsAttribute as CFString, from: appElement) as? [AXUIElement]
		else {
			return nil
		}

		let snapshots = windows.map(snapshot(for:))
		guard let index = bestWindowIndex(for: candidate, in: snapshots) else { return nil }
		return windows[index]
	}

	public static func bestWindowIndex(for candidate: WindowCandidate, in snapshots: [AXWindowSnapshot]) -> Int? {
		if let exact = snapshots.firstIndex(where: { $0.cgWindowID == candidate.cgWindowID }) {
			return exact
		}

		let titleAndBounds = snapshots.indexesMatching { snapshot in
			titleMatches(snapshot.title, title: candidate.windowTitle)
				&& boundsMatch(snapshot.bounds, candidate: candidate)
		}
		if let unambiguous = titleAndBounds.only { return unambiguous }

		let boundsOnly = snapshots.indexesMatching { boundsMatch($0.bounds, candidate: candidate) }
		if let unambiguous = boundsOnly.only { return unambiguous }

		let titleOnly = snapshots.indexesMatching { titleMatches($0.title, title: candidate.windowTitle) }
		if let unambiguous = titleOnly.only { return unambiguous }

		return snapshots.count == 1 ? 0 : nil
	}

	public static func readTitle(for candidate: WindowCandidate) -> String? {
		let appElement = AXUIElementCreateApplication(candidate.ownerPID)
		guard let windows = copyAttribute(kAXWindowsAttribute as CFString, from: appElement) as? [AXUIElement]
		else {
			return nil
		}

		let matchingWindow = windows.first { window in
			cgWindowID(for: window) == candidate.cgWindowID || boundsMatch(window, candidate: candidate)
		}
		let title = matchingWindow.flatMap { copyAttribute(kAXTitleAttribute as CFString, from: $0) as? String }
		return title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? title : nil
	}

	public static func copyAttribute(_ attribute: CFString, from element: AXUIElement) -> AnyObject? {
		var value: AnyObject?
		let result = AXUIElementCopyAttributeValue(element, attribute, &value)
		return result == .success ? value : nil
	}

	public static func cgWindowID(for window: AXUIElement) -> CGWindowID? {
		var windowID = CGWindowID(0)
		if _AXUIElementGetWindow(window, &windowID) == .success, windowID != 0 {
			return windowID
		}

		guard let value = copyAttribute("AXWindowNumber" as CFString, from: window) else { return nil }
		if let number = value as? NSNumber { return CGWindowID(number.uint32Value) }
		if let int = value as? Int { return CGWindowID(int) }
		return nil
	}

	private static func snapshot(for window: AXUIElement) -> AXWindowSnapshot {
		AXWindowSnapshot(
			cgWindowID: cgWindowID(for: window),
			title: copyAttribute(kAXTitleAttribute as CFString, from: window) as? String,
			bounds: bounds(for: window)
		)
	}

	private static func bounds(for window: AXUIElement) -> CGRect? {
		guard let position = pointAttribute(kAXPositionAttribute as CFString, from: window),
			let size = sizeAttribute(kAXSizeAttribute as CFString, from: window)
		else {
			return nil
		}
		return CGRect(origin: position, size: size)
	}

	public static func boundsMatch(_ window: AXUIElement, candidate: WindowCandidate, tolerance: Double = 12.0)
		-> Bool
	{
		boundsMatch(bounds(for: window), candidate: candidate, tolerance: tolerance)
	}

	public static func boundsMatch(_ bounds: CGRect?, candidate: WindowCandidate, tolerance: Double = 12.0) -> Bool
	{
		guard let bounds else { return false }
		return abs(bounds.origin.x - candidate.bounds.origin.x) <= tolerance
			&& abs(bounds.origin.y - candidate.bounds.origin.y) <= tolerance
			&& abs(bounds.width - candidate.bounds.width) <= tolerance
			&& abs(bounds.height - candidate.bounds.height) <= tolerance
	}

	public static func titleMatches(_ window: AXUIElement, title: String?) -> Bool {
		guard let title, !title.isEmpty else { return false }
		let windowTitle = copyAttribute(kAXTitleAttribute as CFString, from: window) as? String
		return titleMatches(windowTitle, title: title)
	}

	public static func titleMatches(_ windowTitle: String?, title: String?) -> Bool {
		guard let title, !title.isEmpty else { return false }
		return windowTitle == title
	}

	public static func pointAttribute(_ attribute: CFString, from element: AXUIElement) -> CGPoint? {
		guard let rawValue = copyAttribute(attribute, from: element),
			CFGetTypeID(rawValue as CFTypeRef) == AXValueGetTypeID()
		else {
			return nil
		}
		let value = rawValue as! AXValue
		var point = CGPoint.zero
		return AXValueGetValue(value, .cgPoint, &point) ? point : nil
	}

	public static func sizeAttribute(_ attribute: CFString, from element: AXUIElement) -> CGSize? {
		guard let rawValue = copyAttribute(attribute, from: element),
			CFGetTypeID(rawValue as CFTypeRef) == AXValueGetTypeID()
		else {
			return nil
		}
		let value = rawValue as! AXValue
		var size = CGSize.zero
		return AXValueGetValue(value, .cgSize, &size) ? size : nil
	}
}

private extension Array {
	func indexesMatching(_ isMatch: (Element) -> Bool) -> [Int] {
		enumerated().compactMap { index, element in isMatch(element) ? index : nil }
	}
}

private extension Array where Element == Int {
	var only: Int? { count == 1 ? self[0] : nil }
}
