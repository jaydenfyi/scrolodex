import Testing
@testable import ScrolodexCore

@Suite("Menu bar icon configuration")
struct MenuBarIconConfigurationTests {
    @Test("uses a square template icon sized for the menu bar")
    func usesSquareTemplateIcon() {
        #expect(MenuBarIconConfiguration.resourceName == "MenuBarIcon")
        #expect(MenuBarIconConfiguration.resourceExtension == "svg")
        #expect(MenuBarIconConfiguration.pointSize == 18)
        #expect(MenuBarIconConfiguration.statusItemLength == 24)
    }
}
