import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Settings trigger summary")
struct SettingsTriggerSummaryTests {
    @Test("disabled triggers show disabled summary")
    func disabledSummary() {
        let summary = SettingsTriggerSummary(
            enabled: false,
            flags: 0,
            overlayMode: .default,
            monitorScope: nil,
            keyboardNavigationEnabled: false
        )

        #expect(summary.chips == ["Disabled"])
    }

    @Test("enabled triggers include configured traits")
    func enabledSummary() {
        let summary = SettingsTriggerSummary(
            enabled: true,
            flags: CGEventFlags.maskAlternate.rawValue,
            overlayMode: .tooltip,
            monitorScope: .allMonitors,
            keyboardNavigationEnabled: true
        )

        #expect(summary.chips == ["Option", "Tooltip", "All Screens", "Keyboard"])
        #expect(summary.compactChips == ["⌥", "Tooltip", "All", "Keys"])
    }
}
