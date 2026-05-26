import CoreGraphics

public enum WindowStackFilter {
	public static func candidates(
		from windows: [WindowCandidate],
		under cursor: CGPoint,
		excludingOwnerNames excludedOwnerNames: Set<String>
	) -> [WindowCandidate] {
		windows.filter { window in
			window.layer == 0
				&& window.alpha > 0
				&& window.bounds.width > 0
				&& window.bounds.height > 0
				&& window.bounds.contains(cursor)
				&& !excludedOwnerNames.contains(window.ownerName)
		}
	}

	private static let maximumAcceptableLayer = 20

	public static func allWindows(
		from windows: [WindowCandidate],
		monitorScope: MonitorScope,
		screenBounds: CGRect,
		excludingOwnerNames excludedOwnerNames: Set<String>
	) -> [WindowCandidate] {
		windows.filter { window in
			window.layer <= maximumAcceptableLayer
				&& window.alpha > 0
				&& window.bounds.width > 0
				&& window.bounds.height > 0
				&& (monitorScope == .allMonitors || window.bounds.intersects(screenBounds))
				&& !excludedOwnerNames.contains(window.ownerName)
		}
	}

	public static func sameApp(
		from windows: [WindowCandidate],
		appName: String,
		under cursor: CGPoint,
		excludingOwnerNames excludedOwnerNames: Set<String>
	) -> [WindowCandidate] {
		windows.filter { window in
			window.layer == 0
				&& window.alpha > 0
				&& window.bounds.width > 0
				&& window.bounds.height > 0
				&& window.bounds.contains(cursor)
				&& window.ownerName == appName
				&& !excludedOwnerNames.contains(window.ownerName)
		}
	}

	public static func appWindows(
		from windows: [WindowCandidate],
		ownerPIDs: Set<pid_t>,
		monitorScope: MonitorScope,
		screenBounds: CGRect,
		excludingOwnerNames excludedOwnerNames: Set<String>
	) -> [WindowCandidate] {
		windows.filter { window in
			ownerPIDs.contains(window.ownerPID)
				&& window.layer <= maximumAcceptableLayer
				&& window.alpha > 0
				&& window.bounds.width > 0
				&& window.bounds.height > 0
				&& (monitorScope == .allMonitors || window.bounds.intersects(screenBounds))
				&& !excludedOwnerNames.contains(window.ownerName)
		}
	}
}
