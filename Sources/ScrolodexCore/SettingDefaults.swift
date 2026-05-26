/// Canonical fallback values for all user-configurable settings.
///
/// Every `?? literal` in this codebase that represents a setting the user can
/// change via the Preferences window should reference `SettingDefaults.xxx`
/// instead of a magic number.  This gives us a single source of truth and makes
/// it obvious which values are user-facing.
///
/// Implementation-detail constants (e.g. cursor relocation thresholds, Space
/// switcher velocities) stay local to their owning module.
public enum SettingDefaults {

	// MARK: - Visual
	public static let peekOpacity: Double = 0.94
	public static let peekEnabled: Bool = true
	public static let theme: OverlayTheme = .default

	// MARK: - Behavior
	public static let animate: Bool = true
	public static let wrapAround: Bool = true
	public static let scrollSensitivity: Double = 6
	public static let showOnPress: Bool = true
	public static let invertDirection: Bool = false
	public static let keyboardNavigationEnabled: Bool = false

	// MARK: - Dock
	public static let showPreviewOnHover: Bool = true

	// MARK: - Default modes (use `.rawValue` when a UserDefaults string is needed)
	public static let overlayMode: OverlayPresentationMode = .default
	public static let monitorScope: MonitorScope = .currentMonitor

	// MARK: - Desktop switch
	public static let desktopSwitchEnabled: Bool = false
	public static let desktopSwitchAnimate: Bool = true
	public static let desktopSwitchWrapAround: Bool = true
	public static let desktopSwitchKeyboardNavEnabled: Bool = false
}
