import Testing
@testable import ScrolodexCore

@Suite("Overlay theme")
struct OverlayThemeTests {
    @Test("defaults to system theme")
    func defaultsToSystem() {
        #expect(OverlayTheme.default == .system)
        #expect(OverlayTheme(rawValue: "") ?? .default == .system)
    }

    @Test("supports system theme")
    func supportsSystem() {
        #expect(OverlayTheme(rawValue: "system") == .system)
        #expect(OverlayTheme.system.displayName == "System")
        #expect(OverlayTheme.allCases.contains(.system))
    }

    @Test("supports dark theme")
    func supportsDark() {
        #expect(OverlayTheme(rawValue: "dark") == .dark)
        #expect(OverlayTheme.dark.displayName == "Dark")
        #expect(OverlayTheme.allCases.contains(.dark))
    }

    @Test("supports light theme")
    func supportsLight() {
        #expect(OverlayTheme(rawValue: "light") == .light)
        #expect(OverlayTheme.light.displayName == "Light")
        #expect(OverlayTheme.allCases.contains(.light))
    }

    @Test("allCases order is system, light, dark")
    func allCasesOrder() {
        #expect(OverlayTheme.allCases == [.system, .light, .dark])
    }

    @Test("dark tokens use white text and dark backgrounds")
    func darkTokenColors() {
        let tokens = OverlayColorTokens.tokens(for: .dark)
        #expect(tokens.primaryText.alpha == 1.0)
        #expect(tokens.primaryText.red == 1.0)
        #expect(tokens.background.alpha < 1.0)
        #expect(tokens.background.red < 0.1)
        #expect(tokens.selectedFill.blue > tokens.selectedFill.red)
    }

    @Test("light tokens use dark text and light backgrounds")
    func lightTokenColors() {
        let tokens = OverlayColorTokens.tokens(for: .light)
        #expect(tokens.primaryText.red < 0.2)
        #expect(tokens.primaryText.alpha == 1.0)
        #expect(tokens.background.red > 0.9)
        #expect(tokens.background.alpha < 1.0)
        #expect(tokens.selectedFill.alpha > 0)
    }

    @Test("light theme selected fill is darker than unselected")
    func lightSelectedDarkerThanUnselected() {
        let tokens = OverlayColorTokens.tokens(for: .light)
        #expect(tokens.selectedFill.alpha > tokens.unselectedFill.alpha)
    }

    @Test("token color white init sets all channels equally")
    func tokenColorWhiteInit() {
        let color = TokenColor(white: 0.5, alpha: 0.8)
        #expect(color.red == 0.5)
        #expect(color.green == 0.5)
        #expect(color.blue == 0.5)
        #expect(color.alpha == 0.8)
    }
}
