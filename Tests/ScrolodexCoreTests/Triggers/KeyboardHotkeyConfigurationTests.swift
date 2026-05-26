import CoreGraphics
import Testing
@testable import ScrolodexCore

@Suite("Keyboard hotkey configuration")
struct KeyboardHotkeyConfigurationTests {
    @Test("matches exact modifiers and key code")
    func matchesExact() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 50)
        #expect(config.matches([.maskCommand, .maskAlternate], 50))
        #expect(!config.matches([.maskCommand], 50))
        #expect(!config.matches([.maskCommand, .maskAlternate], 51))
        #expect(!config.matches([.maskCommand, .maskAlternate, .maskShift], 50))
    }

    @Test("ignores non-modifier flags when matching")
    func ignoresNonModifiers() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 50)
        #expect(config.matches([.maskCommand, .maskAlternate, .maskSecondaryFn], 50))
    }

    @Test("display name includes modifiers and key")
    func displayName() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 50)
        #expect(config.displayName == "Command + Option + `")
    }

    @Test("compact display name uses modifier symbols")
    func compactDisplayName() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskAlternate], keyCode: 50)
        #expect(config.compactDisplayName == "⌘ + ⌥ + `")
    }

    @Test("compact modifier display name uses separators")
    func compactModifierDisplayName() {
        #expect(
            KeyboardHotkeyConfiguration.compactModifierDisplayName(
                from: [.maskCommand, .maskAlternate, .maskShift]) == "⌘ + ⌥ + ⇧")
        #expect(KeyboardHotkeyConfiguration.compactModifierDisplayName(from: []) == nil)
    }

    @Test("display name shows key only when no modifiers")
    func displayNameKeyOnly() {
        let config = KeyboardHotkeyConfiguration(flags: [], keyCode: 50)
        #expect(config.displayName == "`")
    }

    @Test("Tab and Space display correct key names")
    func displayNameTabAndSpace() {
        let tab = KeyboardHotkeyConfiguration(flags: [], keyCode: 48)
        #expect(tab.displayName == "Tab")
        let space = KeyboardHotkeyConfiguration(flags: [], keyCode: 49)
        #expect(space.displayName == "Space")
    }

    @Test("Escape display name includes key name")
    func displayNameEscape() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskAlternate], keyCode: 53)
        #expect(config.displayName == "Option + Esc")
    }

    @Test("display name uses correct ANSI key positions")
    func displayNameANSIKeyPositions() {
        #expect(KeyboardHotkeyConfiguration(flags: [], keyCode: 35).displayName == "P")
        #expect(KeyboardHotkeyConfiguration(flags: [], keyCode: 36).displayName == "Return")
        #expect(KeyboardHotkeyConfiguration(flags: [], keyCode: 47).displayName == ".")
    }

    @Test("display name includes navigation and extended function keys")
    func displayNameNavigationAndExtendedFunctionKeys() {
        #expect(KeyboardHotkeyConfiguration(flags: [], keyCode: 123).displayName == "Left")
        #expect(KeyboardHotkeyConfiguration(flags: [], keyCode: 106).displayName == "F16")
    }

    @Test("display name shows modifiers only for unknown key code")
    func displayNameModifiersOnlyUnknownKey() {
        let config = KeyboardHotkeyConfiguration(flags: [.maskCommand], keyCode: 200)
        #expect(config.displayName == "Command")
    }

    @Test("allBindings returns forward then backward")
    func allBindingsOrder() {
        let forward = KeyboardHotkeyConfiguration(flags: [.maskCommand], keyCode: 50)
        let backward = KeyboardHotkeyConfiguration(flags: [.maskCommand, .maskShift], keyCode: 50)
        let binding = KeyboardNavigationBinding(enabled: true, forward: forward, backward: backward)
        let all = binding.allBindings
        #expect(all.count == 2)
        #expect(all[0] == forward)
        #expect(all[1] == backward)
    }

    @Test("allBindings empty when disabled")
    func allBindingsDisabled() {
        let forward = KeyboardHotkeyConfiguration(flags: [.maskCommand], keyCode: 50)
        let binding = KeyboardNavigationBinding(enabled: false, forward: forward, backward: nil)
        #expect(binding.allBindings.isEmpty)
    }
}
