import CoreGraphics

public enum TriggerScope: String, CaseIterable, Sendable {
	case underCursor
	case currentScreen
	case dockHover

	public var displayName: String {
		switch self {
		case .underCursor: "Under Cursor"
		case .currentScreen: "On Screen"
		case .dockHover: "Dock"
		}
	}
}

public enum TriggerFilter: String, CaseIterable, Sendable {
	case allApps
	case sameApp

	public var displayName: String {
		switch self {
		case .allApps: "All Apps"
		case .sameApp: "Same App"
		}
	}
}

public enum MonitorScope: String, CaseIterable, Sendable {
	case currentMonitor
	case allMonitors

	public var displayName: String {
		switch self {
		case .currentMonitor: "This Screen"
		case .allMonitors: "All Screens"
		}
	}
}

public struct TriggerConfiguration: Equatable, Sendable {
	public let scope: TriggerScope
	public let filter: TriggerFilter

	public init(scope: TriggerScope, filter: TriggerFilter) {
		self.scope = scope
		self.filter = filter
	}

	public var displayName: String {
		switch (scope, filter) {
		case (.underCursor, .allApps): "Windows Under Cursor"
		case (.currentScreen, .allApps): "Windows on Screen"
		case (.underCursor, .sameApp): "App Windows Under Cursor"
		case (.currentScreen, .sameApp): "App Windows on Screen"
		case (.dockHover, _): "Dock Windows"
		}
	}
}
