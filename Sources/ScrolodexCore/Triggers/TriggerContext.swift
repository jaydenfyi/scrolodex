import CoreGraphics

public struct TriggerContext: Equatable, Sendable {
	public let scope: TriggerScope
	public let filter: TriggerFilter
	public let overlayMode: OverlayPresentationMode
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let theme: OverlayTheme
	public let monitorScope: MonitorScope
	public let invertDirection: Bool
	public let animate: Bool
	public let wrapAround: Bool
	public let scrollThreshold: Double
	public let dockBundleID: String?

	public init(
		scope: TriggerScope,
		filter: TriggerFilter,
		overlayMode: OverlayPresentationMode,
		peekEnabled: Bool,
		peekOpacity: Double,
		theme: OverlayTheme,
		monitorScope: MonitorScope,
		invertDirection: Bool,
		animate: Bool,
		wrapAround: Bool,
		scrollThreshold: Double,
		dockBundleID: String? = nil
	) {
		self.scope = scope
		self.filter = filter
		self.overlayMode = overlayMode
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
		self.monitorScope = monitorScope
		self.invertDirection = invertDirection
		self.animate = animate
		self.wrapAround = wrapAround
		self.scrollThreshold = scrollThreshold
		self.dockBundleID = dockBundleID
	}

	public static func from(
		trigger: TriggerHotkey,
		scrollThreshold: Double
	) -> TriggerContext {
		TriggerContext(
			scope: trigger.configuration.scope,
			filter: trigger.configuration.filter,
			overlayMode: trigger.overlayMode,
			peekEnabled: trigger.peekEnabled,
			peekOpacity: trigger.peekOpacity,
			theme: trigger.theme,
			monitorScope: trigger.monitorScope,
			invertDirection: trigger.invertDirection,
			animate: trigger.animate,
			wrapAround: trigger.wrapAround,
			scrollThreshold: scrollThreshold
		)
	}

	public static func from(
		gestureConfig: GestureTriggerConfig,
		scrollThreshold: Double
	) -> TriggerContext {
		TriggerContext(
			scope: gestureConfig.scope,
			filter: gestureConfig.filter,
			overlayMode: gestureConfig.overlayMode,
			peekEnabled: gestureConfig.peekEnabled,
			peekOpacity: gestureConfig.peekOpacity,
			theme: gestureConfig.theme,
			monitorScope: gestureConfig.monitorScope,
			invertDirection: gestureConfig.invertDirection,
			animate: gestureConfig.animate,
			wrapAround: gestureConfig.wrapAround,
			scrollThreshold: scrollThreshold
		)
	}

	public static func from(
		dockConfig: DockHoverConfiguration,
		bundleID: String,
		scrollThreshold: Double
	) -> TriggerContext {
		TriggerContext(
			scope: .dockHover,
			filter: .sameApp,
			overlayMode: dockConfig.overlayMode,
			peekEnabled: dockConfig.peekEnabled,
			peekOpacity: dockConfig.peekOpacity,
			theme: dockConfig.theme,
			monitorScope: dockConfig.monitorScope,
			invertDirection: dockConfig.invertDirection,
			animate: dockConfig.animate,
			wrapAround: dockConfig.wrapAround,
			scrollThreshold: scrollThreshold,
			dockBundleID: bundleID
		)
	}
}
