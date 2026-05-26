import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Trigger context")
struct TriggerContextTests {
    private func makeTrigger(
        scope: TriggerScope = .underCursor,
        filter: TriggerFilter = .allApps,
        overlayMode: OverlayPresentationMode = .tooltip,
        peekEnabled: Bool = true,
        peekOpacity: Double = 0.94,
        theme: OverlayTheme = .dark,
        monitorScope: MonitorScope = .currentMonitor,
        invertDirection: Bool = false,
        animate: Bool = true,
        wrapAround: Bool = true
    ) -> TriggerHotkey {
        TriggerHotkey(
            configuration: TriggerConfiguration(scope: scope, filter: filter),
            hotkey: HotkeyConfiguration(flags: .maskControl),
            overlayMode: overlayMode,
            peekEnabled: peekEnabled,
            peekOpacity: peekOpacity,
            theme: theme,
            monitorScope: monitorScope,
            showOnPress: true,
            invertDirection: invertDirection,
            animate: animate,
            wrapAround: wrapAround,
            keyboardNavigation: KeyboardNavigationBinding()
        )
    }

    @Test("from trigger maps all fields")
    func fromTriggerMapsAllFields() {
        let trigger = makeTrigger(
            scope: .currentScreen, filter: .sameApp,
            overlayMode: .list, peekEnabled: false, peekOpacity: 0.5,
            theme: .light, monitorScope: .allMonitors,
            invertDirection: true, animate: false, wrapAround: false
        )
        let context = TriggerContext.from(trigger: trigger, scrollThreshold: 8)

        #expect(context.scope == .currentScreen)
        #expect(context.filter == .sameApp)
        #expect(context.overlayMode == .list)
        #expect(context.peekEnabled == false)
        #expect(context.peekOpacity == 0.5)
        #expect(context.theme == .light)
        #expect(context.monitorScope == .allMonitors)
        #expect(context.invertDirection == true)
        #expect(context.animate == false)
        #expect(context.wrapAround == false)
        #expect(context.scrollThreshold == 8)
        #expect(context.dockBundleID == nil)
    }

    @Test("from dock config uses config fields with global peek/theme")
    func fromDockConfig() {
        let config = DockHoverConfiguration(
            enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue,
            monitorScope: .allMonitors, overlayMode: .list,
            invertDirection: true, animate: false, wrapAround: false)
        let context = TriggerContext.from(
            dockConfig: config, peekEnabled: true, peekOpacity: 0.8, theme: OverlayTheme.light,
            bundleID: "com.example.app", scrollThreshold: 6)

        #expect(context.scope == .dockHover)
        #expect(context.filter == .sameApp)
        #expect(context.overlayMode == .list)
        #expect(context.peekEnabled == true)
        #expect(context.peekOpacity == 0.8)
        #expect(context.theme == OverlayTheme.light)
        #expect(context.monitorScope == MonitorScope.allMonitors)
        #expect(context.invertDirection == true)
        #expect(context.animate == false)
        #expect(context.wrapAround == false)
        #expect(context.dockBundleID == "com.example.app")
    }

    @Test("dock config showPreviewOnHover false disables peek")
    func dockConfigDisablesPeek() {
        let config = DockHoverConfiguration(
            enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue,
            monitorScope: .currentMonitor)
        let context = TriggerContext.from(
            dockConfig: config, peekEnabled: false, peekOpacity: 0.94, theme: OverlayTheme.default,
            bundleID: "com.example.app", scrollThreshold: 6)

        #expect(context.peekEnabled == false)
    }

    @Test("dock config uses its own monitor scope")
    func dockConfigUsesOwnMonitorScope() {
        let config = DockHoverConfiguration(
            enabled: true, modifierFlags: CGEventFlags.maskAlternate.rawValue,
            monitorScope: .allMonitors)
        let context = TriggerContext.from(
            dockConfig: config, peekEnabled: true, peekOpacity: 0.94, theme: OverlayTheme.default,
            bundleID: "com.example.app", scrollThreshold: 6)

        #expect(context.monitorScope == MonitorScope.allMonitors)
    }
}
