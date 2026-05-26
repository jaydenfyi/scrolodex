import CoreGraphics

public struct OverlayDisplayConfig: Equatable, Sendable {
	public let presentationMode: OverlayPresentationMode
	public let scrollAnimationEnabled: Bool
	public let peekEnabled: Bool
	public let peekOpacity: Double
	public let theme: OverlayTheme

	public static let `default` = OverlayDisplayConfig(
		presentationMode: .default,
		scrollAnimationEnabled: false,
		peekEnabled: SettingDefaults.peekEnabled,
		peekOpacity: SettingDefaults.peekOpacity,
		theme: .default
	)

	public init(
		presentationMode: OverlayPresentationMode,
		scrollAnimationEnabled: Bool,
		peekEnabled: Bool,
		peekOpacity: Double,
		theme: OverlayTheme
	) {
		self.presentationMode = presentationMode
		self.scrollAnimationEnabled = scrollAnimationEnabled
		self.peekEnabled = peekEnabled
		self.peekOpacity = peekOpacity
		self.theme = theme
	}

	public init(context: TriggerContext) {
		self.presentationMode = context.overlayMode
		self.scrollAnimationEnabled = context.animate
		self.peekEnabled = context.peekEnabled
		self.peekOpacity = context.peekOpacity
		self.theme = context.theme
	}
}
