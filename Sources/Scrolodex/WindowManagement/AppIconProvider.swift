import AppKit

@MainActor
final class AppIconProvider {
	private var cache: [pid_t: NSImage] = [:]

	func icon(for pid: pid_t, ownerName: String) -> NSImage? {
		if let cached = cache[pid] {
			return cached
		}

		let app = NSRunningApplication(processIdentifier: pid)
		let icon = app?.icon
		if let icon {
			cache[pid] = icon
		}
		return icon
	}

	func clear() {
		cache.removeAll()
	}
}
