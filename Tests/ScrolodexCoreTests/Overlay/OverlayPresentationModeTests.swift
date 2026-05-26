import Testing
@testable import ScrolodexCore

@Suite("Overlay presentation mode")
struct OverlayPresentationModeTests {
    @Test("defaults to tooltip overlay")
    func defaultsToTooltip() {
        #expect(OverlayPresentationMode.default == OverlayPresentationMode.tooltip)
        #expect(OverlayPresentationMode(rawValue: "") ?? .default == OverlayPresentationMode.tooltip)
    }

    @Test("supports no navigation overlay")
    func supportsNoneMode() {
        #expect(OverlayPresentationMode(rawValue: "none") == OverlayPresentationMode.none)
        #expect(OverlayPresentationMode.allCases.contains(OverlayPresentationMode.none))
    }

    @Test("supports legacy list mode")
    func supportsListMode() {
        #expect(OverlayPresentationMode(rawValue: "list") == .list)
    }

    @Test("supports tooltip mode")
    func supportsTooltipMode() {
        #expect(OverlayPresentationMode(rawValue: "tooltip") == .tooltip)
        #expect(OverlayPresentationMode.tooltip.displayName == "Tooltip")
        #expect(OverlayPresentationMode.allCases.contains(.tooltip))
    }

    @Test("supports tile mode")
    func supportsTileMode() {
        #expect(OverlayPresentationMode(rawValue: "tile") == .tile)
        #expect(OverlayPresentationMode.allCases.contains(.tile))
    }
}
